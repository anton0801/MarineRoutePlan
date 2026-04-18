import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - AppState (EnvironmentObject)

class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @AppStorage("themeMode") var themeMode: String = "dark"
    @AppStorage("userName") var userName: String = ""
    @AppStorage("userEmail") var userEmail: String = ""
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    @AppStorage("weatherAlertsEnabled") var weatherAlertsEnabled: Bool = true
    @AppStorage("fuelAlertsEnabled") var fuelAlertsEnabled: Bool = true
    @AppStorage("distanceUnit") var distanceUnit: String = "NM"
    @AppStorage("fuelUnit") var fuelUnit: String = "L"
    
    var colorScheme: ColorScheme? {
        switch themeMode {
        case "dark": return .dark
        case "light": return .light
        default: return nil
        }
    }
    
    func loginAsDemo() {
        userName = "Alex Navigator"
        userEmail = "demo@marineroute.app"
        isLoggedIn = true
    }
    
    func logout() {
        isLoggedIn = false
        userName = ""
        userEmail = ""
    }
    
    func deleteAccount() {
        isLoggedIn = false
        userName = ""
        userEmail = ""
        hasCompletedOnboarding = false
        UserDefaults.standard.removeObject(forKey: "savedRoutes")
        UserDefaults.standard.removeObject(forKey: "savedBoats")
        UserDefaults.standard.removeObject(forKey: "tripLogs")
    }
}

// MARK: - RouteViewModel

class RouteViewModel: ObservableObject {
    @Published var routes: [Route] = []
    @Published var activeRoute: Route?
    @Published var draftWaypoints: [Waypoint] = []
    @Published var draftRouteName: String = ""
    @Published var selectedStartName: String = ""
    @Published var selectedEndName: String = ""
    
    private let storageKey = "savedRoutes"
    
    init() { load() }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Route].self, from: data) {
            routes = decoded
        } else {
            routes = Route.sampleRoutes
            save()
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(routes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func addWaypoint(_ waypoint: Waypoint) {
        draftWaypoints.append(waypoint)
    }
    
    func removeWaypoint(at offsets: IndexSet) {
        draftWaypoints.remove(atOffsets: offsets)
    }
    
    func buildRoute() -> Route? {
        guard draftWaypoints.count >= 2 else { return nil }
        let distance = Double.random(in: 8...35)
        let time = distance / 18.0
        let fuel = time * 25
        let route = Route(id: UUID(), name: draftRouteName.isEmpty ? "New Route" : draftRouteName,
                          waypoints: draftWaypoints,
                          totalDistance: distance, estimatedTime: time, fuelRequired: fuel,
                          createdAt: Date(), status: .planned)
        return route
    }
    
    func saveRoute(_ route: Route) {
        routes.insert(route, at: 0)
        draftWaypoints = []
        draftRouteName = ""
        save()
    }
    
    func deleteRoute(at offsets: IndexSet) {
        routes.remove(atOffsets: offsets)
        save()
    }
    
    func setActiveRoute(_ route: Route) {
        var updated = route
        updated.status = .active
        activeRoute = updated
        if let idx = routes.firstIndex(where: { $0.id == route.id }) {
            routes[idx] = updated
        }
        save()
    }
    
    func calculateFuel(distance: Double, consumptionPerHour: Double, speed: Double) -> Double {
        let time = distance / speed
        return time * consumptionPerHour
    }
    
    var totalDistance: Double { routes.reduce(0) { $0 + $1.totalDistance } }
    var totalFuel: Double { routes.reduce(0) { $0 + $1.fuelRequired } }
}

// MARK: - BoatViewModel

class BoatViewModel: ObservableObject {
    @Published var boats: [Boat] = []
    @Published var selectedBoat: Boat?
    
    private let storageKey = "savedBoats"
    
    init() { load() }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Boat].self, from: data) {
            boats = decoded
            selectedBoat = boats.first(where: { $0.isDefault }) ?? boats.first
        } else {
            boats = Boat.sampleBoats
            selectedBoat = boats.first
            save()
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(boats) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func addBoat(_ boat: Boat) {
        var b = boat
        if boats.isEmpty { b.isDefault = true }
        boats.append(b)
        if b.isDefault { selectedBoat = b }
        save()
    }
    
    func deleteBoat(at offsets: IndexSet) {
        boats.remove(atOffsets: offsets)
        selectedBoat = boats.first(where: { $0.isDefault }) ?? boats.first
        save()
    }
    
    func setDefault(_ boat: Boat) {
        boats = boats.map {
            var b = $0
            b.isDefault = b.id == boat.id
            return b
        }
        selectedBoat = boat
        save()
    }
    
    func updateBoat(_ boat: Boat) {
        if let idx = boats.firstIndex(where: { $0.id == boat.id }) {
            boats[idx] = boat
            if boat.isDefault { selectedBoat = boat }
        }
        save()
    }
}

// MARK: - TripLogViewModel

class TripLogViewModel: ObservableObject {
    @Published var logs: [TripLog] = []
    
    private let storageKey = "tripLogs"
    
    init() { load() }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([TripLog].self, from: data) {
            logs = decoded
        } else {
            logs = TripLog.sampleLogs
            save()
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func addLog(_ log: TripLog) {
        logs.insert(log, at: 0)
        save()
    }
    
    func deleteLog(at offsets: IndexSet) {
        logs.remove(atOffsets: offsets)
        save()
    }
    
    var totalDistance: Double { logs.reduce(0) { $0 + $1.distanceCovered } }
    var totalFuel: Double { logs.reduce(0) { $0 + $1.fuelUsed } }
    var totalHours: Double { logs.reduce(0) { $0 + $1.duration } }
    var avgEfficiency: Double {
        guard totalDistance > 0 else { return 0 }
        return totalFuel / totalDistance
    }
}

// MARK: - WeatherViewModel

class WeatherViewModel: ObservableObject {
    @Published var current: WeatherCondition = .sample
    @Published var isLoading: Bool = false
    
    func refresh() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.current = WeatherCondition(
                windSpeed: Double.random(in: 5...25),
                windDirection: ["N","NE","E","SE","S","SW","W","NW"].randomElement()!,
                waveHeight: Double.random(in: 0.2...1.8),
                visibility: Double.random(in: 8...20),
                temperature: Double.random(in: 18...30),
                description: ["Clear skies", "Partly cloudy", "Light breeze", "Scattered clouds"].randomElement()!,
                recommendation: [.safe, .safe, .caution].randomElement()!,
                timestamp: Date()
            )
            self?.isLoading = false
        }
    }
    
    var riskLevel: String {
        switch current.recommendation {
        case .safe: return "Low"
        case .caution: return "Medium"
        case .stayAshore: return "High"
        }
    }
    
    var riskColor: Color {
        switch current.recommendation {
        case .safe: return MarineColors.safeGreen
        case .caution: return MarineColors.warningAmber
        case .stayAshore: return MarineColors.dangerRed
        }
    }
}

// MARK: - AlertsViewModel

class AlertsViewModel: ObservableObject {
    @Published var alerts: [Alert] = Alert.samples
    
    var unreadCount: Int { alerts.filter { !$0.isRead }.count }
    
    func markRead(_ alert: Alert) {
        if let idx = alerts.firstIndex(where: { $0.id == alert.id }) {
            alerts[idx].isRead = true
        }
    }
    
    func markAllRead() {
        alerts = alerts.map { var a = $0; a.isRead = true; return a }
    }
    
    func dismiss(_ alert: Alert) {
        alerts.removeAll { $0.id == alert.id }
    }
    
    func scheduleWeatherNotification(message: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Marine Route Plan"
            content.body = message
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request)
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
