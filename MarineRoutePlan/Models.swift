import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct Waypoint: Identifiable, Codable {
    var id = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
    var type: WaypointType
    
    enum WaypointType: String, Codable, CaseIterable {
        case start = "Start"
        case end = "End"
        case stop = "Stop"
        case fuel = "Fuel"
        case shelter = "Shelter"
    }
    
    var coordinate: (Double, Double) { (latitude, longitude) }
}

struct ValidationRow: Codable {
    let id: Int?
    let isValid: Bool
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case isValid = "is_valid"
        case createdAt = "created_at"
    }
}

struct Route: Identifiable, Codable {
    var id = UUID()
    var name: String
    var waypoints: [Waypoint]
    var totalDistance: Double // nautical miles
    var estimatedTime: Double // hours
    var fuelRequired: Double // liters
    var createdAt: Date
    var status: RouteStatus
    
    enum RouteStatus: String, Codable {
        case planned = "Planned"
        case active = "Active"
        case completed = "Completed"
    }
    
    static var sampleRoutes: [Route] {
        [
            Route(id: UUID(), name: "Coastal Morning Run",
                  waypoints: [
                    Waypoint(name: "Marina Bay", latitude: 38.35, longitude: 0.42, type: .start),
                    Waypoint(name: "Cove Rest", latitude: 38.40, longitude: 0.50, type: .stop),
                    Waypoint(name: "Blue Harbor", latitude: 38.45, longitude: 0.58, type: .end)
                  ],
                  totalDistance: 12.4, estimatedTime: 1.5, fuelRequired: 45,
                  createdAt: Date().addingTimeInterval(-86400 * 2), status: .completed),
            Route(id: UUID(), name: "Weekend Island Trip",
                  waypoints: [
                    Waypoint(name: "Home Port", latitude: 38.33, longitude: 0.40, type: .start),
                    Waypoint(name: "Fuel Dock", latitude: 38.38, longitude: 0.55, type: .fuel),
                    Waypoint(name: "Santa Island", latitude: 38.50, longitude: 0.70, type: .end)
                  ],
                  totalDistance: 28.6, estimatedTime: 3.2, fuelRequired: 95,
                  createdAt: Date().addingTimeInterval(-86400 * 7), status: .completed)
        ]
    }
}

struct TripLog: Identifiable, Codable {
    var id = UUID()
    var routeId: UUID?
    var routeName: String
    var date: Date
    var distanceCovered: Double
    var fuelUsed: Double
    var duration: Double // hours
    var notes: String
    var photoCount: Int
    var rating: Int // 1-5
    
    static var sampleLogs: [TripLog] {
        [
            TripLog(id: UUID(), routeId: nil, routeName: "Coastal Morning Run",
                    date: Date().addingTimeInterval(-86400 * 2), distanceCovered: 12.4,
                    fuelUsed: 42, duration: 1.4, notes: "Perfect conditions. Light breeze.", photoCount: 8, rating: 5),
            TripLog(id: UUID(), routeId: nil, routeName: "Quick Bay Loop",
                    date: Date().addingTimeInterval(-86400 * 5), distanceCovered: 7.2,
                    fuelUsed: 25, duration: 0.9, notes: "Slight chop after noon.", photoCount: 3, rating: 4),
            TripLog(id: UUID(), routeId: nil, routeName: "Weekend Island Trip",
                    date: Date().addingTimeInterval(-86400 * 7), distanceCovered: 28.6,
                    fuelUsed: 91, duration: 3.1, notes: "Amazing sunset. Anchored at cove.", photoCount: 24, rating: 5)
        ]
    }
}

struct Boat: Identifiable, Codable {
    var id = UUID()
    var name: String
    var type: BoatType
    var enginePower: Int // HP
    var fuelCapacity: Double // liters
    var fuelConsumptionPerHour: Double // liters/hour
    var maxSpeed: Double // knots
    var cruisingSpeed: Double // knots
    var manufacturer: String
    var year: Int
    var isDefault: Bool
    
    enum BoatType: String, Codable, CaseIterable {
        case motorboat = "Motorboat"
        case sailboat = "Sailboat"
        case yacht = "Yacht"
        case speedboat = "Speedboat"
        case catamaran = "Catamaran"
        case inflatable = "Inflatable"
    }
    
    static var sampleBoats: [Boat] {
        [
            Boat(id: UUID(), name: "Sea Breeze", type: .motorboat, enginePower: 150,
                 fuelCapacity: 120, fuelConsumptionPerHour: 25, maxSpeed: 28, cruisingSpeed: 20,
                 manufacturer: "Bayliner", year: 2019, isDefault: true)
        ]
    }
}

struct WeatherCondition: Codable {
    var windSpeed: Double // knots
    var windDirection: String
    var waveHeight: Double // meters
    var visibility: Double // km
    var temperature: Double // celsius
    var description: String
    var recommendation: WeatherRecommendation
    var timestamp: Date
    
    enum WeatherRecommendation: String, Codable {
        case safe = "Safe to Navigate"
        case caution = "Navigate with Caution"
        case stayAshore = "Stay Ashore"
    }
    
    static var sample: WeatherCondition {
        WeatherCondition(windSpeed: 12, windDirection: "NE", waveHeight: 0.6,
                         visibility: 15, temperature: 24,
                         description: "Partly cloudy with light breeze",
                         recommendation: .safe, timestamp: Date())
    }
}

struct StoredState {
    var tracking: [String: String]
    var navigation: [String: String]
    var endpoint: String?
    var mode: String?
    var isFirstLaunch: Bool
    var permission: PermissionData
    
    struct PermissionData {
        var isGranted: Bool
        var isDenied: Bool
        var lastAsked: Date?
    }
}

struct Alert: Identifiable {
    var id = UUID()
    var type: AlertType
    var message: String
    var timestamp: Date
    var isRead: Bool
    
    enum AlertType: String {
        case weather = "Weather"
        case fuel = "Fuel"
        case route = "Route"
        case system = "System"
    }
    
    static var samples: [Alert] {
        [
            Alert(id: UUID(), type: .weather, message: "Wind speed increasing to 18 knots in 2 hours", timestamp: Date(), isRead: false),
            Alert(id: UUID(), type: .fuel, message: "Fuel below 25% — refuel recommended before next trip", timestamp: Date().addingTimeInterval(-3600), isRead: false),
            Alert(id: UUID(), type: .route, message: "Saved route 'Coastal Morning Run' is ready", timestamp: Date().addingTimeInterval(-7200), isRead: true)
        ]
    }
}

struct UserProfile: Codable {
    var name: String
    var email: String
    var licenseNumber: String
    var homePort: String
    var totalTrips: Int
    var totalDistance: Double
    var joinDate: Date
    
    static var demo: UserProfile {
        UserProfile(name: "Alex Navigator", email: "demo@marineroute.app",
                    licenseNumber: "ML-2024-7821", homePort: "Marina Bay",
                    totalTrips: 47, totalDistance: 842.5, joinDate: Date().addingTimeInterval(-86400 * 180))
    }
}

enum AppEvent {
    case initialized(ApplicationState)
    case trackingReceived([String: Any])
    case navigationReceived([String: Any])
    case validationCompleted(Bool)
    case endpointFetched(String)
    case permissionRequested
    case permissionGranted
    case permissionDenied
    case timeout
    case networkStatusChanged(Bool)
}

// MARK: - State

struct ApplicationState {
    var tracking: [String: String]
    var navigation: [String: String]
    var endpoint: String?
    var mode: String?
    var isFirstLaunch: Bool
    var permission: PermissionState
    var metadata: [String: String]
    var isLocked: Bool
    
    struct PermissionState {
        var isGranted: Bool
        var isDenied: Bool
        var lastAsked: Date?
        
        var canAsk: Bool {
            guard !isGranted && !isDenied else { return false }
            if let date = lastAsked {
                return Date().timeIntervalSince(date) / 86400 >= 3
            }
            return true
        }
        
        static var initial: PermissionState {
            PermissionState(isGranted: false, isDenied: false, lastAsked: nil)
        }
    }
    
    func isOrganic() -> Bool {
        tracking["af_status"] == "Organic"
    }
    
    func hasTracking() -> Bool {
        !tracking.isEmpty
    }
    
    static var initial: ApplicationState {
        ApplicationState(
            tracking: [:],
            navigation: [:],
            endpoint: nil,
            mode: nil,
            isFirstLaunch: true,
            permission: .initial,
            metadata: [:],
            isLocked: false
        )
    }
}

enum EventError: Error {
    case validationFailed
    case networkError
    case timeout
    case notFound
}

enum NetworkError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
    case noDataAvailable
}

struct MarineRouteConfig {
    static let appID = "6762529080"
    static let devKey = "dcbJsMnMQxEqHiJwZAAmD9"
}
