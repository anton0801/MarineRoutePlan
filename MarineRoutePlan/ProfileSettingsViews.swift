import SwiftUI
import UserNotifications

// MARK: - Boat Profile (Screens 21-22)

struct BoatProfileView: View {
    @EnvironmentObject var boatVM: BoatViewModel
    @State private var showAddBoat = false
    @State private var editingBoat: Boat? = nil
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            OceanBackground()
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FLEET").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                        Text("My Boats").font(MarineFont.display(22, weight: .bold)).foregroundColor(.white)
                    }
                    Spacer()
                    Button { showAddBoat = true } label: {
                        Image(systemName: "plus").font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black).frame(width: 36, height: 36)
                            .background(MarineGradients.aquaAccent).clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if boatVM.boats.isEmpty {
                            EmptyStateView(icon: "sailboat.fill", title: "No Boats Added", subtitle: "Add your vessel to calculate fuel and plan routes")
                                .padding(.top, 60)
                        } else {
                            ForEach(boatVM.boats) { boat in
                                BoatCard(boat: boat, onDefault: { boatVM.setDefault(boat) }, onEdit: { editingBoat = boat })
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showAddBoat) { AddEditBoatView(boat: nil) { boat in boatVM.addBoat(boat) } }
        .sheet(item: $editingBoat) { boat in AddEditBoatView(boat: boat) { updated in boatVM.updateBoat(updated) } }
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.3)) { appeared = true } }
    }
}

struct BoatCard: View {
    let boat: Boat
    var onDefault: () -> Void
    var onEdit: () -> Void
    
    var body: some View {
        MarineCard(padding: 16) {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(MarineColors.aquaGlow.opacity(0.1)).frame(width: 52, height: 52)
                        BoatTopView(size: 36, glowColor: MarineColors.aquaGlow)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(boat.name).font(MarineFont.label(16)).foregroundColor(.white)
                            if boat.isDefault {
                                Text("DEFAULT").font(MarineFont.mono(9)).foregroundColor(.black)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(MarineGradients.aquaAccent).clipShape(Capsule())
                            }
                        }
                        Text("\(boat.type.rawValue) • \(boat.year) \(boat.manufacturer)")
                            .font(MarineFont.body(12)).foregroundColor(MarineColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil").font(.system(size: 14))
                            .foregroundColor(MarineColors.aquaGlow)
                            .frame(width: 32, height: 32)
                            .background(MarineColors.aquaGlow.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                
                Divider().background(MarineColors.cardBorder)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    BoatSpec(label: "Engine", value: "\(boat.enginePower)HP")
                    BoatSpec(label: "Max Speed", value: "\(Int(boat.maxSpeed))kn")
                    BoatSpec(label: "Cruise", value: "\(Int(boat.cruisingSpeed))kn")
                    BoatSpec(label: "Fuel Cap.", value: "\(Int(boat.fuelCapacity))L")
                    BoatSpec(label: "Consump.", value: "\(Int(boat.fuelConsumptionPerHour))L/h")
                    BoatSpec(label: "Type", value: boat.type.rawValue)
                }
                
                if !boat.isDefault {
                    Button(action: onDefault) {
                        Text("Set as Default")
                            .font(MarineFont.label(13))
                            .foregroundColor(MarineColors.aquaGlow)
                            .frame(maxWidth: .infinity).frame(height: 38)
                            .background(MarineColors.aquaGlow.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(MarineColors.aquaGlow.opacity(0.2), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct BoatSpec: View {
    let label: String; let value: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(MarineFont.mono(13, weight: .bold)).foregroundColor(.white)
            Text(label).font(MarineFont.body(10)).foregroundColor(MarineColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(MarineColors.waterLayer.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

// MARK: - Add/Edit Boat

struct AddEditBoatView: View {
    var boat: Boat?
    var onSave: (Boat) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String = ""
    @State private var type: Boat.BoatType = .motorboat
    @State private var manufacturer: String = ""
    @State private var year: String = "2020"
    @State private var enginePower: String = "150"
    @State private var fuelCapacity: String = "120"
    @State private var consumption: String = "25"
    @State private var maxSpeed: String = "28"
    @State private var cruisingSpeed: String = "20"
    
    var body: some View {
        ZStack {
            OceanBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    HStack {
                        Button { presentationMode.wrappedValue.dismiss() } label: {
                            Text("Cancel").font(MarineFont.body(15)).foregroundColor(MarineColors.textSecondary)
                        }
                        Spacer()
                        Text(boat == nil ? "Add Boat" : "Edit Boat").font(MarineFont.label(16)).foregroundColor(.white)
                        Spacer()
                        Button {
                            let b = Boat(id: boat?.id ?? UUID(), name: name.isEmpty ? "My Boat" : name,
                                        type: type, enginePower: Int(enginePower) ?? 150,
                                        fuelCapacity: Double(fuelCapacity) ?? 120,
                                        fuelConsumptionPerHour: Double(consumption) ?? 25,
                                        maxSpeed: Double(maxSpeed) ?? 28, cruisingSpeed: Double(cruisingSpeed) ?? 20,
                                        manufacturer: manufacturer, year: Int(year) ?? 2020,
                                        isDefault: boat?.isDefault ?? false)
                            onSave(b)
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Save").font(MarineFont.label(15)).foregroundColor(MarineColors.aquaGlow)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                    
                    MarineCard {
                        VStack(spacing: 14) {
                            MarineTextField(icon: "sailboat", placeholder: "Boat name", text: $name)
                            MarineTextField(icon: "building.2", placeholder: "Manufacturer", text: $manufacturer)
                            MarineTextField(icon: "calendar", placeholder: "Year", text: $year, keyboardType: .numberPad)
                            
                            HStack {
                                Text("Type").font(MarineFont.body(14)).foregroundColor(MarineColors.textSecondary)
                                Spacer()
                                Picker("", selection: $type) {
                                    ForEach(Boat.BoatType.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                                }
                                .pickerStyle(.menu)
                                .accentColor(MarineColors.aquaGlow)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    MarineCard {
                        VStack(spacing: 12) {
                            Text("SPECIFICATIONS").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            FuelInputRow(icon: "bolt.fill", label: "Engine Power (HP)", value: $enginePower, keyboardType: .numberPad)
                            FuelInputRow(icon: "fuelpump.fill", label: "Fuel Capacity (L)", value: $fuelCapacity, keyboardType: .decimalPad)
                            FuelInputRow(icon: "drop.fill", label: "Consumption (L/hr)", value: $consumption, keyboardType: .decimalPad)
                            FuelInputRow(icon: "gauge.high", label: "Max Speed (kn)", value: $maxSpeed, keyboardType: .decimalPad)
                            FuelInputRow(icon: "speedometer", label: "Cruise Speed (kn)", value: $cruisingSpeed, keyboardType: .decimalPad)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 80)
                }
            }
        }
        .onAppear {
            if let b = boat {
                name = b.name; type = b.type; manufacturer = b.manufacturer
                year = "\(b.year)"; enginePower = "\(b.enginePower)"
                fuelCapacity = "\(Int(b.fuelCapacity))"; consumption = "\(Int(b.fuelConsumptionPerHour))"
                maxSpeed = "\(Int(b.maxSpeed))"; cruisingSpeed = "\(Int(b.cruisingSpeed))"
            }
        }
    }
}

// MARK: - Alerts View (Screen 23)

struct AlertsView: View {
    @EnvironmentObject var alertsVM: AlertsViewModel
    @Environment(\.presentationMode) var presentationMode
    
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
                    Text("Alerts").font(MarineFont.label(16)).foregroundColor(.white)
                    Spacer()
                    Button { alertsVM.markAllRead() } label: {
                        Text("Mark all read").font(MarineFont.body(12)).foregroundColor(MarineColors.aquaGlow)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)
                
                if alertsVM.alerts.isEmpty {
                    Spacer()
                    EmptyStateView(icon: "bell.slash.fill", title: "No Alerts", subtitle: "You're all caught up")
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(alertsVM.alerts) { alert in
                                AlertRow(alert: alert, onRead: { alertsVM.markRead(alert) }, onDismiss: { alertsVM.dismiss(alert) })
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

struct AlertRow: View {
    let alert: Alert
    var onRead: () -> Void
    var onDismiss: () -> Void
    
    var iconName: String {
        switch alert.type {
        case .weather: return "cloud.bolt.fill"
        case .fuel: return "fuelpump.fill"
        case .route: return "map.fill"
        case .system: return "gear"
        }
    }
    
    var iconColor: Color {
        switch alert.type {
        case .weather: return MarineColors.warningAmber
        case .fuel: return MarineColors.fuelOrange
        case .route: return MarineColors.aquaGlow
        case .system: return MarineColors.textSecondary
        }
    }
    
    var body: some View {
        MarineCard(padding: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(iconColor.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: iconName).font(.system(size: 16)).foregroundColor(iconColor)
                    if !alert.isRead {
                        Circle().fill(MarineColors.dangerRed).frame(width: 8, height: 8).offset(x: 13, y: -13)
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(alert.message).font(MarineFont.body(13)).foregroundColor(.white).lineLimit(2)
                    Text(alert.timestamp, style: .relative).font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    if !alert.isRead {
                        Button(action: onRead) {
                            Image(systemName: "checkmark").font(.system(size: 12, weight: .semibold))
                                .foregroundColor(MarineColors.safeGreen)
                        }
                    }
                    Button(action: onDismiss) {
                        Image(systemName: "xmark").font(.system(size: 12, weight: .semibold))
                            .foregroundColor(MarineColors.textDim)
                    }
                }
            }
        }
        .opacity(alert.isRead ? 0.6 : 1.0)
    }
}

// MARK: - Settings View (Screen 24)

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var alertsVM: AlertsViewModel
    @State private var showDeleteConfirm = false
    @State private var showLogoutConfirm = false
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            OceanBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("PREFERENCES").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                            Text("Settings").font(MarineFont.display(22, weight: .bold)).foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                    
                    // Appearance
                    SettingsSection(title: "APPEARANCE") {
                        VStack(spacing: 0) {
                            SettingRow(icon: "moon.stars.fill", iconColor: MarineColors.aquaGlow, label: "Theme") {
                                Picker("", selection: $appState.themeMode) {
                                    Text("Dark").tag("dark")
                                    Text("Light").tag("light")
                                    Text("System").tag("system")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 160)
                            }
                        }
                    }
                    
                    // Units
                    SettingsSection(title: "UNITS") {
                        VStack(spacing: 0) {
                            SettingRow(icon: "arrow.left.and.right", iconColor: MarineColors.routeGlow, label: "Distance") {
                                Picker("", selection: $appState.distanceUnit) {
                                    Text("NM").tag("NM")
                                    Text("km").tag("km")
                                    Text("mi").tag("mi")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 120)
                            }
                            Divider().background(MarineColors.cardBorder).padding(.leading, 48)
                            SettingRow(icon: "fuelpump.fill", iconColor: MarineColors.fuelAmber, label: "Fuel") {
                                Picker("", selection: $appState.fuelUnit) {
                                    Text("L").tag("L")
                                    Text("gal").tag("gal")
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 90)
                            }
                        }
                    }
                    
                    // Notifications
                    SettingsSection(title: "NOTIFICATIONS") {
                        VStack(spacing: 0) {
                            SettingRow(icon: "bell.fill", iconColor: MarineColors.aquaGlow, label: "Enable Notifications") {
                                Toggle("", isOn: $appState.notificationsEnabled)
                                    .tint(MarineColors.aquaGlow)
                                    .onChange(of: appState.notificationsEnabled) { enabled in
                                        if enabled {
                                            alertsVM.scheduleWeatherNotification(message: "Marine Route Plan notifications enabled")
                                        } else {
                                            alertsVM.cancelAllNotifications()
                                        }
                                    }
                            }
                            if appState.notificationsEnabled {
                                Divider().background(MarineColors.cardBorder).padding(.leading, 48)
                                SettingRow(icon: "cloud.bolt.fill", iconColor: MarineColors.warningAmber, label: "Weather Alerts") {
                                    Toggle("", isOn: $appState.weatherAlertsEnabled).tint(MarineColors.aquaGlow)
                                        .onChange(of: appState.weatherAlertsEnabled) { enabled in
                                            if enabled {
                                                alertsVM.scheduleWeatherNotification(message: "Weather alerts enabled — you'll be notified of dangerous conditions")
                                            }
                                        }
                                }
                                Divider().background(MarineColors.cardBorder).padding(.leading, 48)
                                SettingRow(icon: "fuelpump.fill", iconColor: MarineColors.fuelOrange, label: "Fuel Alerts") {
                                    Toggle("", isOn: $appState.fuelAlertsEnabled).tint(MarineColors.aquaGlow)
                                }
                            }
                        }
                    }
                    
                    // Account
                    SettingsSection(title: "ACCOUNT") {
                        VStack(spacing: 0) {
                            Button { showLogoutConfirm = true } label: {
                                SettingRow(icon: "rectangle.portrait.and.arrow.right.fill",
                                           iconColor: MarineColors.warningAmber, label: "Sign Out") { EmptyView() }
                            }
                            .buttonStyle(.plain)
                            
                            Divider().background(MarineColors.cardBorder).padding(.leading, 48)
                            
                            Button { showDeleteConfirm = true } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(MarineColors.dangerRed.opacity(0.15)).frame(width: 32, height: 32)
                                        Image(systemName: "person.crop.circle.badge.minus").font(.system(size: 15)).foregroundColor(MarineColors.dangerRed)
                                    }
                                    Text("Delete Account").font(MarineFont.body(15)).foregroundColor(MarineColors.dangerRed)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(MarineColors.textDim)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 13)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Version
                    Text("Marine Route Plan v1.0.0")
                        .font(MarineFont.body(12)).foregroundColor(MarineColors.textDim)
                        .padding(.bottom, 100)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.3)) { appeared = true } }
        .alert("Sign Out", isPresented: $showLogoutConfirm) {
            Button("Sign Out", role: .destructive) { appState.logout() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Are you sure you want to sign out?") }
        .alert("Delete Account", isPresented: $showDeleteConfirm) {
            Button("Delete Everything", role: .destructive) { appState.deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will permanently delete your account, all routes, and trip logs. This cannot be undone.") }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim).padding(.horizontal, 20)
            MarineCard(padding: 0) { content }
                .padding(.horizontal, 20)
        }
    }
}

struct SettingRow<Trailing: View>: View {
    let icon: String; let iconColor: Color; let label: String; let trailing: Trailing
    
    init(icon: String, iconColor: Color, label: String, @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon; self.iconColor = iconColor; self.label = label; self.trailing = trailing()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(iconColor.opacity(0.15)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(iconColor)
            }
            Text(label).font(MarineFont.body(15)).foregroundColor(.white)
            Spacer()
            trailing
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
    }
}

// MARK: - Profile View (Screen 25)

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var boatVM: BoatViewModel
    @EnvironmentObject var alertsVM: AlertsViewModel
    @State private var selectedTab: ProfileTab = .overview
    @State private var showSettings = false
    @State private var showBoats = false
    @State private var showWeather = false
    @State private var showFuel = false
    
    enum ProfileTab: String, CaseIterable { case overview = "Overview"; case boats = "Boats"; case settings = "Settings" }
    
    var body: some View {
        NavigationView {
            ZStack {
                OceanBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle().fill(MarineGradients.aquaAccent).frame(width: 80, height: 80)
                                Text(appState.userName.prefix(2).uppercased())
                                    .font(MarineFont.display(28, weight: .black)).foregroundColor(.black)
                            }
                            VStack(spacing: 4) {
                                Text(appState.userName.isEmpty ? "Captain" : appState.userName)
                                    .font(MarineFont.display(20, weight: .bold)).foregroundColor(.white)
                                Text(appState.userEmail).font(MarineFont.body(13)).foregroundColor(MarineColors.textSecondary)
                            }
                            
                            HStack(spacing: 24) {
                                ProfileStat(value: "47", label: "Trips")
                                ProfileStat(value: "842", label: "NM")
                                ProfileStat(value: "3", label: "Boats")
                            }
                        }
                        .padding(.top, 20)
                        
                        // Quick actions
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            QuickActionCard(icon: "sailboat.fill", label: "My Boats", color: MarineColors.aquaGlow) { showBoats = true }
                            QuickActionCard(icon: "cloud.sun.fill", label: "Weather", color: MarineColors.warningAmber) { showWeather = true }
                            QuickActionCard(icon: "fuelpump.fill", label: "Fuel Calc", color: MarineColors.fuelOrange) { showFuel = true }
                            QuickActionCard(icon: "gear", label: "Settings", color: MarineColors.textSecondary) { showSettings = true }
                        }
                        .padding(.horizontal, 20)
                        
                        // Current boat
                        if let boat = boatVM.selectedBoat {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("ACTIVE VESSEL").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                                    .padding(.horizontal, 20)
                                BoatCard(boat: boat, onDefault: {}, onEdit: {})
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showBoats) { BoatProfileView().environmentObject(boatVM) }
        .sheet(isPresented: $showWeather) { WeatherFullView().environmentObject(WeatherViewModel()) }
        .sheet(isPresented: $showFuel) { FuelCalculatorView().environmentObject(boatVM) }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(appState).environmentObject(alertsVM)
        }
    }
}

struct ProfileStat: View {
    let value: String; let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(MarineFont.mono(22, weight: .black)).foregroundColor(.white)
            Text(label).font(MarineFont.body(12)).foregroundColor(MarineColors.textSecondary)
        }
    }
}

struct QuickActionCard: View {
    let icon: String; let label: String; var color: Color; var action: () -> Void
    @State private var pressed = false
    
    var body: some View {
        Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { pressed = false; action() }
        }) {
            MarineCard(padding: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: icon).font(.system(size: 22)).foregroundColor(color)
                    Text(label).font(MarineFont.label(14)).foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(pressed ? 0.95 : 1.0)
    }
}
