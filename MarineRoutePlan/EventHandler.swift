import Foundation
import AppsFlyerLib

final class MarineRouteEventHandler {
    private let storage: StorageService
    private let validation: ValidationService
    private let network: NetworkService
    private let notification: NotificationService
    
    private var state: ApplicationState = .initial
    
    init(
        storage: StorageService,
        validation: ValidationService,
        network: NetworkService,
        notification: NotificationService
    ) {
        self.storage = storage
        self.validation = validation
        self.network = network
        self.notification = notification
    }
    
    // MARK: - Event Handlers
    
    func handle(_ event: AppEvent) async throws -> ApplicationState {
        switch event {
        case .initialized:
            return try await handleInitialized()
            
        case .trackingReceived(let data):
            return handleTrackingReceived(data)
            
        case .navigationReceived(let data):
            return handleNavigationReceived(data)
            
        case .validationCompleted(let isValid):
            return try await handleValidationCompleted(isValid)
            
        case .endpointFetched(let url):
            return handleEndpointFetched(url)
            
        case .permissionRequested:
            return await handlePermissionRequested()
            
        case .permissionGranted:
            return handlePermissionGranted()
            
        case .permissionDenied:
            return handlePermissionDenied()
            
        case .timeout, .networkStatusChanged:
            return state
        }
    }
    
    // MARK: - Private Handlers
    
    private func handleInitialized() async throws -> ApplicationState {
        let stored = storage.loadState()
        state.tracking = stored.tracking
        state.navigation = stored.navigation
        state.mode = stored.mode
        state.isFirstLaunch = stored.isFirstLaunch
        state.permission = ApplicationState.PermissionState(
            isGranted: stored.permission.isGranted,
            isDenied: stored.permission.isDenied,
            lastAsked: stored.permission.lastAsked
        )
        
        return state
    }
    
    private func handleTrackingReceived(_ data: [String: Any]) -> ApplicationState {
        let converted = data.mapValues { "\($0)" }
        state.tracking = converted
        storage.saveTracking(converted)
        return state
    }
    
    private func handleNavigationReceived(_ data: [String: Any]) -> ApplicationState {
        let converted = data.mapValues { "\($0)" }
        state.navigation = converted
        storage.saveNavigation(converted)
        return state
    }
    
    private func handleValidationCompleted(_ isValid: Bool) async throws -> ApplicationState {
        if !isValid {
            throw EventError.validationFailed
        }
        
        // Validation passed - execute business logic
        return try await executeBusinessLogic()
    }
    
    private func executeBusinessLogic() async throws -> ApplicationState {
        guard !state.isLocked, state.hasTracking() else {
            throw EventError.notFound
        }
        
        // Check temp_url
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            // state.endpoint = temp
            state.endpoint = temp
            state.mode = "Active"
            state.isFirstLaunch = false
            state.isLocked = true
            
            storage.saveEndpoint(temp)
            storage.saveMode("Active")
            storage.markLaunched()
            
            // ✅ ПУБЛИКУЕМ СОБЫТИЕ!
            EventBus.shared.publish(.endpointFetched(temp))
            return state
        }
        
        // Check organic + first launch
        let attributionProcessed = state.metadata["attribution_processed"] == "true"
        if state.isOrganic() && state.isFirstLaunch && !attributionProcessed {
            state.metadata["attribution_processed"] = "true"
            try await executeOrganicFlow()
        }
        
        // Fetch endpoint
        let trackingDict = state.tracking.mapValues { $0 as Any }
        let url = try await network.fetchEndpoint(tracking: trackingDict)
        
        EventBus.shared.publish(.endpointFetched(url))
        
        return state
    }
    
    private func executeOrganicFlow() async throws {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !state.isLocked else { return }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        var fetched = try await network.fetchAttribution(deviceID: deviceID)
        
        for (key, value) in state.navigation {
            if fetched[key] == nil {
                fetched[key] = value
            }
        }
        
        let converted = fetched.mapValues { "\($0)" }
        state.tracking = converted
        storage.saveTracking(converted)
    }
    
    private func handleEndpointFetched(_ url: String) -> ApplicationState {
        state.endpoint = url
        state.mode = "Active"
        state.isFirstLaunch = false
        state.isLocked = true
        
        storage.saveEndpoint(url)
        storage.saveMode("Active")
        storage.markLaunched()
        
        return state
    }
    
    private func handlePermissionRequested() async -> ApplicationState {
        var localPermission = state.permission
        
        let updatedPermission = await withCheckedContinuation {
            (continuation: CheckedContinuation<ApplicationState.PermissionState, Never>) in
            
            notification.requestPermission { granted in
                var permission = localPermission
                
                if granted {
                    permission.isGranted = true
                    permission.isDenied = false
                    permission.lastAsked = Date()
                    self.notification.registerForPush()
                    EventBus.shared.publish(.permissionGranted)
                } else {
                    permission.isGranted = false
                    permission.isDenied = true
                    permission.lastAsked = Date()
                    EventBus.shared.publish(.permissionDenied)
                }
                
                continuation.resume(returning: permission)
            }
        }
        
        state.permission = updatedPermission
        storage.savePermissions(updatedPermission)
        return state
    }
    
    private func handlePermissionGranted() -> ApplicationState {
        return state
    }
    
    private func handlePermissionDenied() -> ApplicationState {
        return state
    }
    
    func validate() async throws -> Bool {
        guard state.hasTracking() else {
            return false
        }
        
        do {
            return try await validation.validate()
        } catch {
            print("🌊 [MarineRoute] Validation error: \(error)")
            throw error
        }
    }
    
    func canAskPermission() -> Bool {
        state.permission.canAsk
    }
    
    func deferPermission() {
        state.permission.lastAsked = Date()
        storage.savePermissions(state.permission)
    }
}
