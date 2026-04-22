import Foundation
import Combine

@MainActor
final class MarineRouteViewModel: ObservableObject {
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    @Published var navigateToMain = false
    @Published var navigateToWeb = false
    
    private let eventHandler: MarineRouteEventHandler
    private var cancellables = Set<AnyCancellable>()
    private var timeoutTask: Task<Void, Never>?
    
    init(eventHandler: MarineRouteEventHandler) {
        self.eventHandler = eventHandler
        subscribeToEvents()
    }
    
    private func subscribeToEvents() {
        EventBus.shared.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)
    }
    
    private func handleEvent(_ event: AppEvent) {
        Task {
            switch event {
            case .endpointFetched(let url):
                let _ = try await eventHandler.handle(.endpointFetched(url))
                if eventHandler.canAskPermission() {
                    showPermissionPrompt = true
                } else {
                    navigateToWeb = true
                }
                
            case .permissionGranted, .permissionDenied:
                showPermissionPrompt = false
                navigateToWeb = true
                
            case .timeout:
                timeoutTask?.cancel()
                navigateToMain = true
                
            case .networkStatusChanged(let isConnected):
                showOfflineView = !isConnected
                
            default:
                break
            }
        }
    }
    
    func initialize() {
        Task {
            do {
                _ = try await eventHandler.handle(.initialized(.initial))
            } catch {
                print("🌊 [MarineRoute] Init error: \(error)")
            }
            
            scheduleTimeout()
        }
    }
    
    func handleTracking(_ data: [String: Any]) {
        Task {
            do {
                _ = try await eventHandler.handle(.trackingReceived(data))
                await performValidation()
            } catch {
                print("🌊 [MarineRoute] Tracking error: \(error)")
                navigateToMain = true
            }
        }
    }
    
    func handleNavigation(_ data: [String: Any]) {
        Task {
            do {
                _ = try await eventHandler.handle(.navigationReceived(data))
            } catch {
                print("🌊 [MarineRoute] Navigation error: \(error)")
            }
        }
    }
    
    func requestPermission() {
        Task {
            do {
                _ = try await eventHandler.handle(.permissionRequested)
            } catch {
                print("🌊 [MarineRoute] Permission error: \(error)")
                showPermissionPrompt = false
                navigateToWeb = true
            }
        }
    }
    
    func deferPermission() {
        Task {
            eventHandler.deferPermission()
            showPermissionPrompt = false
            navigateToWeb = true
        }
    }
    
    func networkStatusChanged(_ isConnected: Bool) {
        EventBus.shared.publish(.networkStatusChanged(isConnected))
    }
    
    func timeout() {
        if !valPassed {
            EventBus.shared.publish(.timeout)
        }
    }
    
    private var valPassed = false
    
    private func performValidation() async {
        if !valPassed {
            do {
                let isValid = try await eventHandler.validate()
                
                if isValid {
                    _ = try await eventHandler.handle(.validationCompleted(true))
                } else {
                    timeoutTask?.cancel()
                    navigateToMain = true
                }
                valPassed = true
            } catch {
                print("🌊 [MarineRoute] Validation error: \(error)")
                timeoutTask?.cancel()
                navigateToMain = true
            }
        }
    }
    
    private func scheduleTimeout() {
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            await timeout()
        }
    }
}
