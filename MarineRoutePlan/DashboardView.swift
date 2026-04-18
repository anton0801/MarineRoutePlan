import SwiftUI

// MARK: - Main Tab Bar

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var routeVM = RouteViewModel()
    @StateObject var boatVM = BoatViewModel()
    @StateObject var tripVM = TripLogViewModel()
    @StateObject var weatherVM = WeatherViewModel()
    @StateObject var alertsVM = AlertsViewModel()
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .environmentObject(routeVM)
                    .environmentObject(boatVM)
                    .environmentObject(weatherVM)
                    .environmentObject(alertsVM)
                    .tag(0)
                
                RoutePlannerRootView()
                    .environmentObject(routeVM)
                    .environmentObject(boatVM)
                    .tag(1)
                
                TripLogListView()
                    .environmentObject(tripVM)
                    .tag(2)
                
                AnalyticsView()
                    .environmentObject(tripVM)
                    .environmentObject(routeVM)
                    .tag(3)
                
                ProfileView()
                    .environmentObject(boatVM)
                    .environmentObject(alertsVM)
                    .tag(4)
            }
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $selectedTab, unreadAlerts: alertsVM.unreadCount)
        }
        .preferredColorScheme(appState.colorScheme)
        .onAppear { weatherVM.refresh() }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    var unreadAlerts: Int
    
    let items: [(icon: String, label: String)] = [
        ("map.fill", "Dashboard"),
        ("arrow.triangle.turn.up.right.diamond.fill", "Route"),
        ("book.fill", "Log"),
        ("chart.bar.fill", "Analytics"),
        ("person.fill", "Profile")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<items.count, id: \.self) { i in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selectedTab = i }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == i {
                                Circle()
                                    .fill(MarineColors.aquaGlow.opacity(0.15))
                                    .frame(width: 40, height: 40)
                            }
                            Image(systemName: items[i].icon)
                                .font(.system(size: 18, weight: selectedTab == i ? .semibold : .regular))
                                .foregroundColor(selectedTab == i ? MarineColors.aquaGlow : MarineColors.textDim)
                            
                            if i == 4 && unreadAlerts > 0 {
                                Circle().fill(MarineColors.dangerRed).frame(width: 8, height: 8)
                                    .offset(x: 10, y: -10)
                            }
                        }
                        Text(items[i].label)
                            .font(MarineFont.body(10, weight: selectedTab == i ? .semibold : .regular))
                            .foregroundColor(selectedTab == i ? MarineColors.aquaGlow : MarineColors.textDim)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 20)
        .background(
            ZStack {
                MarineColors.oceanMid
                Rectangle().fill(MarineColors.aquaGlow.opacity(0.04))
            }
        )
        .overlay(Rectangle().fill(MarineColors.cardBorder).frame(height: 1), alignment: .top)
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @EnvironmentObject var routeVM: RouteViewModel
    @EnvironmentObject var boatVM: BoatViewModel
    @EnvironmentObject var weatherVM: WeatherViewModel
    @EnvironmentObject var alertsVM: AlertsViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var showingAlerts = false
    @State private var showingStartRoute = false
    @State private var showingPlanTrip = false
    @State private var showingLogRide = false
    @State private var appeared = false
    
    var body: some View {
        NavigationView {
            ZStack {
                OceanBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Good \(timeOfDay)")
                                    .font(MarineFont.body(13))
                                    .foregroundColor(MarineColors.textSecondary)
                                Text(appState.userName.isEmpty ? "Captain" : appState.userName)
                                    .font(MarineFont.display(22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Button { showingAlerts = true } label: {
                                ZStack {
                                    Circle().fill(MarineColors.waterLayer).frame(width: 42, height: 42)
                                    Image(systemName: "bell.fill").font(.system(size: 16)).foregroundColor(MarineColors.textSecondary)
                                    if alertsVM.unreadCount > 0 {
                                        ZStack {
                                            Circle().fill(MarineColors.dangerRed).frame(width: 16, height: 16)
                                            Text("\(alertsVM.unreadCount)").font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                                        }
                                        .offset(x: 12, y: -12)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : -10)
                        
                        // Map top-view card
                        MarineCard(padding: 0) {
                            ZStack {
                                // Map grid
                                OceanMapView()
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                                // Active route overlay
                                if let route = routeVM.activeRoute, route.waypoints.count >= 2 {
                                    RoutePathView(waypoints: route.waypoints.map { ($0.latitude, $0.longitude) })
                                        .frame(height: 220)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                
                                // Boat center
                                BoatTopView(size: 48, glowColor: MarineColors.aquaGlow)
                                
                                // Status overlay
                                VStack {
                                    Spacer()
                                    HStack(spacing: 8) {
                                        if let route = routeVM.activeRoute {
                                            ActiveRouteBadge(route: route)
                                        } else {
                                            Text("No Active Route")
                                                .font(MarineFont.body(12))
                                                .foregroundColor(MarineColors.textSecondary)
                                                .padding(.horizontal, 10).padding(.vertical, 5)
                                                .background(MarineColors.cardBase.opacity(0.8))
                                                .clipShape(Capsule())
                                        }
                                        Spacer()
                                        // Weather badge
                                        WeatherMicroBadge(weather: weatherVM.current)
                                    }
                                    .padding(12)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        
                        // Stats row
                        HStack(spacing: 10) {
                            let boat = boatVM.selectedBoat
                            StatPill(value: boat != nil ? "\(Int(boat!.fuelCapacity))L" : "--",
                                     label: "Fuel Cap", icon: "fuelpump.fill", color: MarineColors.fuelAmber)
                            
                            StatPill(value: routeVM.activeRoute != nil ? String(format: "%.1f", routeVM.activeRoute!.totalDistance) : "--",
                                     label: "NM Route", icon: "arrow.triangle.turn.up.right.circle.fill", color: MarineColors.routeGlow)
                            
                            StatPill(value: routeVM.activeRoute != nil ? String(format: "%.1fh", routeVM.activeRoute!.estimatedTime) : "--",
                                     label: "ETA", icon: "clock.fill", color: MarineColors.aquaGlow)
                        }
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            MarinePrimaryButton("Start Route", icon: "play.fill") {
                                if let first = routeVM.routes.first { routeVM.setActiveRoute(first) }
                                showingStartRoute = true
                            }
                            HStack(spacing: 12) {
                                MarineSecondaryButton("Plan Trip", icon: "map") { showingPlanTrip = true }
                                MarineSecondaryButton("Log Ride", icon: "plus.circle") { showingLogRide = true }
                            }
                        }
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)
                        
                        // Weather summary
                        WeatherSummaryCard(weather: weatherVM.current, isLoading: weatherVM.isLoading) {
                            weatherVM.refresh()
                        }
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)
                        
                        // Recent routes
                        if !routeVM.routes.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Routes")
                                    .font(MarineFont.label(16))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                
                                ForEach(routeVM.routes.prefix(3)) { route in
                                    RouteRowCard(route: route) {
                                        routeVM.setActiveRoute(route)
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            .opacity(appeared ? 1 : 0)
                        }
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingAlerts) { AlertsView().environmentObject(alertsVM) }
        .sheet(isPresented: $showingStartRoute) {
            ActiveRouteView(route: routeVM.activeRoute ?? routeVM.routes.first ?? Route(
                id: UUID(), name: "No Route", waypoints: [], totalDistance: 0,
                estimatedTime: 0, fuelRequired: 0, createdAt: Date(), status: .planned))
            .environmentObject(routeVM)
        }
        .sheet(isPresented: $showingPlanTrip) {
            RoutePlannerRootView().environmentObject(routeVM).environmentObject(boatVM)
        }
        .sheet(isPresented: $showingLogRide) {
            AddTripLogView { log in
                // handled internally
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) { appeared = true }
        }
    }
    
    var timeOfDay: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Morning" }
        if h < 17 { return "Afternoon" }
        return "Evening"
    }
}

struct OceanMapView: View {
    @State private var gridOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color(hex: "#05111E")
            
            // Moving grid lines
            GeometryReader { geo in
                let size = geo.size
                Group {
                    ForEach(0..<12) { i in
                        Rectangle()
                            .fill(MarineColors.aquaGlow.opacity(0.04))
                            .frame(width: 1, height: size.height)
                            .offset(x: CGFloat(i) * 30 + gridOffset)
                    }
                    ForEach(0..<8) { i in
                        Rectangle()
                            .fill(MarineColors.aquaGlow.opacity(0.04))
                            .frame(width: size.width, height: 1)
                            .offset(y: CGFloat(i) * 30)
                    }
                }
            }
            
            // Depth circles
            ForEach(0..<4) { i in
                Circle()
                    .stroke(MarineColors.aquaGlow.opacity(0.03), lineWidth: 1)
                    .frame(width: CGFloat(60 + i * 40), height: CGFloat(60 + i * 40))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                gridOffset = 30
            }
        }
    }
}

struct ActiveRouteBadge: View {
    let route: Route
    var body: some View {
        HStack(spacing: 5) {
            GlowDot(color: MarineColors.safeGreen)
            Text(route.name)
                .font(MarineFont.body(11, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(MarineColors.cardBase.opacity(0.9))
        .clipShape(Capsule())
    }
}

struct WeatherMicroBadge: View {
    let weather: WeatherCondition
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "wind").font(.system(size: 10)).foregroundColor(MarineColors.aquaGlow)
            Text("\(Int(weather.windSpeed))kn").font(MarineFont.mono(11, weight: .bold)).foregroundColor(.white)
        }
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(MarineColors.cardBase.opacity(0.9))
        .clipShape(Capsule())
    }
}

struct WeatherSummaryCard: View {
    let weather: WeatherCondition
    var isLoading: Bool
    var onRefresh: () -> Void
    
    var body: some View {
        MarineCard {
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CONDITIONS").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                        Text(weather.description).font(MarineFont.label(14)).foregroundColor(.white)
                    }
                    Spacer()
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundColor(MarineColors.aquaGlow)
                            .rotationEffect(.degrees(isLoading ? 360 : 0))
                            .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                    }
                }
                
                HStack(spacing: 0) {
                    WeatherMetric(icon: "wind", value: "\(Int(weather.windSpeed))kn", label: "Wind \(weather.windDirection)")
                    Divider().background(MarineColors.cardBorder).frame(height: 30)
                    WeatherMetric(icon: "water.waves", value: "\(String(format: "%.1f", weather.waveHeight))m", label: "Waves")
                    Divider().background(MarineColors.cardBorder).frame(height: 30)
                    WeatherMetric(icon: "eye.fill", value: "\(Int(weather.visibility))km", label: "Visibility")
                    Divider().background(MarineColors.cardBorder).frame(height: 30)
                    WeatherMetric(icon: "thermometer", value: "\(Int(weather.temperature))°", label: "Temp")
                }
                
                // Recommendation
                HStack(spacing: 8) {
                    Image(systemName: weather.recommendation == .safe ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(recommendationColor)
                        .font(.system(size: 14))
                    Text(weather.recommendation.rawValue)
                        .font(MarineFont.label(13))
                        .foregroundColor(recommendationColor)
                    Spacer()
                }
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(recommendationColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    var recommendationColor: Color {
        switch weather.recommendation {
        case .safe: return MarineColors.safeGreen
        case .caution: return MarineColors.warningAmber
        case .stayAshore: return MarineColors.dangerRed
        }
    }
}

struct WeatherMetric: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(MarineColors.aquaGlow)
            Text(value).font(MarineFont.mono(14, weight: .bold)).foregroundColor(.white)
            Text(label).font(MarineFont.body(10)).foregroundColor(MarineColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RouteRowCard: View {
    let route: Route
    var onActivate: () -> Void
    
    var body: some View {
        MarineCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(MarineColors.aquaGlow.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 16))
                        .foregroundColor(MarineColors.aquaGlow)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(route.name).font(MarineFont.label(14)).foregroundColor(.white).lineLimit(1)
                    HStack(spacing: 8) {
                        Label(String(format: "%.1f NM", route.totalDistance), systemImage: "arrow.left.and.right")
                            .font(MarineFont.body(11))
                            .foregroundColor(MarineColors.textSecondary)
                        Label(String(format: "%.0fL", route.fuelRequired), systemImage: "fuelpump")
                            .font(MarineFont.body(11))
                            .foregroundColor(MarineColors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: onActivate) {
                    Text("Set")
                        .font(MarineFont.label(12))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(MarineGradients.aquaAccent)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
