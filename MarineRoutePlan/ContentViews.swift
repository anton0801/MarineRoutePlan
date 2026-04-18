import SwiftUI

// MARK: - Fuel Calculator (Screens 9-11)

struct FuelCalculatorView: View {
    @EnvironmentObject var boatVM: BoatViewModel
    @State private var distance: String = "20"
    @State private var consumption: String = ""
    @State private var speed: String = ""
    @State private var result: FuelResult?
    @State private var appeared = false
    
    struct FuelResult {
        let fuelNeeded: Double
        let time: Double
        let fuelPerNM: Double
        let recommendation: String
    }
    
    var body: some View {
        ZStack {
            OceanBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 4) {
                        Text("Fuel Calculator").font(MarineFont.display(22, weight: .bold)).foregroundColor(.white)
                        Text("Estimate fuel for your journey").font(MarineFont.body(14)).foregroundColor(MarineColors.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Boat selector
                    if let boat = boatVM.selectedBoat {
                        MarineCard(padding: 14) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8).fill(MarineColors.aquaGlow.opacity(0.1)).frame(width: 38, height: 38)
                                    Image(systemName: "sailboat.fill").font(.system(size: 15)).foregroundColor(MarineColors.aquaGlow)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(boat.name).font(MarineFont.label(14)).foregroundColor(.white)
                                    Text("\(boat.type.rawValue) • \(boat.enginePower)HP").font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary)
                                }
                                Spacer()
                                Button("Change") {
                                    consumption = String(format: "%.0f", boat.fuelConsumptionPerHour)
                                    speed = String(format: "%.0f", boat.cruisingSpeed)
                                }
                                .font(MarineFont.label(12))
                                .foregroundColor(MarineColors.aquaGlow)
                            }
                        }
                        .padding(.horizontal, 20)
                        .onAppear {
                            if consumption.isEmpty { consumption = String(format: "%.0f", boat.fuelConsumptionPerHour) }
                            if speed.isEmpty { speed = String(format: "%.0f", boat.cruisingSpeed) }
                        }
                    }
                    
                    // Inputs
                    MarineCard {
                        VStack(spacing: 16) {
                            Text("VOYAGE PARAMETERS").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            FuelInputRow(icon: "arrow.left.and.right", label: "Distance (NM)", value: $distance, keyboardType: .decimalPad)
                            FuelInputRow(icon: "fuelpump.fill", label: "Consumption (L/hr)", value: $consumption, keyboardType: .decimalPad)
                            FuelInputRow(icon: "speedometer", label: "Speed (knots)", value: $speed, keyboardType: .decimalPad)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    MarinePrimaryButton("Calculate", icon: "function") { calculate() }
                        .padding(.horizontal, 20)
                    
                    // Result
                    if let r = result {
                        FuelResultCard(result: r)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    Spacer().frame(height: 100)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.3)) { appeared = true } }
    }
    
    private func calculate() {
        guard let dist = Double(distance), let cons = Double(consumption), let spd = Double(speed), spd > 0 else { return }
        let time = dist / spd
        let fuel = time * cons
        let perNM = fuel / dist
        let rec = fuel > 80 ? "Carry extra reserve fuel" : fuel > 50 ? "Consider a fuel stop midway" : "Fuel load is optimal"
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            result = FuelResult(fuelNeeded: fuel, time: time, fuelPerNM: perNM, recommendation: rec)
        }
    }
}

struct FuelInputRow: View {
    let icon: String
    let label: String
    @Binding var value: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(MarineColors.aquaGlow).frame(width: 20)
            Text(label).font(MarineFont.body(13)).foregroundColor(MarineColors.textSecondary)
            Spacer()
            TextField("0", text: $value)
                .font(MarineFont.mono(15, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
                .keyboardType(keyboardType)
                .frame(width: 80)
                .accentColor(MarineColors.aquaGlow)
        }
        .padding(.vertical, 4)
    }
}

struct FuelResultCard: View {
    let result: FuelCalculatorView.FuelResult
    
    var body: some View {
        MarineCard {
            VStack(spacing: 16) {
                Text("CALCULATION RESULT").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 0) {
                    ResultMetric(value: String(format: "%.0f", result.fuelNeeded), unit: "L", label: "Total Fuel", color: MarineColors.fuelOrange)
                    Divider().background(MarineColors.cardBorder).frame(height: 40)
                    ResultMetric(value: String(format: "%.1f", result.time), unit: "hr", label: "Travel Time", color: MarineColors.aquaGlow)
                    Divider().background(MarineColors.cardBorder).frame(height: 40)
                    ResultMetric(value: String(format: "%.1f", result.fuelPerNM), unit: "L/NM", label: "Efficiency", color: MarineColors.routeGlow)
                }
                
                // Fuel bar
                VStack(spacing: 6) {
                    HStack {
                        Text("Fuel Required").font(MarineFont.body(12)).foregroundColor(MarineColors.textSecondary)
                        Spacer()
                        Text(String(format: "%.0fL", result.fuelNeeded)).font(MarineFont.mono(13, weight: .bold)).foregroundColor(MarineColors.fuelAmber)
                    }
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(MarineColors.waterLayer).frame(height: 10)
                        let pct = min(result.fuelNeeded / 150.0, 1.0)
                        RoundedRectangle(cornerRadius: 4).fill(MarineGradients.fuelGradient)
                            .frame(width: CGFloat(pct) * (UIScreen.main.bounds.width - 88), height: 10)
                    }
                }
                
                // Recommendation
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill").foregroundColor(MarineColors.fuelAmber).font(.system(size: 12))
                    Text(result.recommendation).font(MarineFont.body(13)).foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(MarineColors.fuelAmber.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct ResultMetric: View {
    let value: String; let unit: String; let label: String; var color: Color
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(MarineFont.mono(20, weight: .bold)).foregroundColor(.white)
                Text(unit).font(MarineFont.body(10)).foregroundColor(MarineColors.textSecondary)
            }
            Text(label).font(MarineFont.body(10)).foregroundColor(MarineColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Weather Full View (Screens 12-14)

struct WeatherFullView: View {
    @EnvironmentObject var weatherVM: WeatherViewModel
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            OceanBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CONDITIONS").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                            Text("Weather & Safety").font(MarineFont.display(22, weight: .bold)).foregroundColor(.white)
                        }
                        Spacer()
                        Button(action: { weatherVM.refresh() }) {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.clockwise").font(.system(size: 12))
                                Text("Refresh").font(MarineFont.label(12))
                            }
                            .foregroundColor(MarineColors.aquaGlow)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(MarineColors.aquaGlow.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                    
                    // Main status
                    MarineCard {
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(weatherVM.current.description)
                                        .font(MarineFont.display(18, weight: .semibold)).foregroundColor(.white)
                                    Text(weatherVM.current.timestamp, style: .time)
                                        .font(MarineFont.body(12)).foregroundColor(MarineColors.textSecondary)
                                }
                                Spacer()
                                Text("\(Int(weatherVM.current.temperature))°C")
                                    .font(MarineFont.mono(32, weight: .bold)).foregroundColor(.white)
                            }
                            
                            // Recommendation banner
                            HStack(spacing: 10) {
                                Image(systemName: weatherVM.current.recommendation == .safe ? "checkmark.shield.fill" :
                                      weatherVM.current.recommendation == .caution ? "exclamationmark.shield.fill" : "xmark.shield.fill")
                                    .font(.system(size: 20)).foregroundColor(weatherVM.riskColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(weatherVM.current.recommendation.rawValue)
                                        .font(MarineFont.label(14)).foregroundColor(weatherVM.riskColor)
                                    Text("Risk Level: \(weatherVM.riskLevel)")
                                        .font(MarineFont.body(12)).foregroundColor(MarineColors.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(weatherVM.riskColor.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Grid of metrics
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        WeatherDetailCard(icon: "wind", label: "Wind Speed",
                                          value: "\(Int(weatherVM.current.windSpeed))",
                                          unit: "knots", subtext: "Direction: \(weatherVM.current.windDirection)", color: MarineColors.aquaGlow)
                        WeatherDetailCard(icon: "water.waves", label: "Wave Height",
                                          value: String(format: "%.1f", weatherVM.current.waveHeight),
                                          unit: "meters", subtext: weatherVM.current.waveHeight < 0.5 ? "Calm" : weatherVM.current.waveHeight < 1.2 ? "Moderate" : "Rough", color: MarineColors.routeGlow)
                        WeatherDetailCard(icon: "eye.fill", label: "Visibility",
                                          value: "\(Int(weatherVM.current.visibility))",
                                          unit: "km", subtext: weatherVM.current.visibility > 10 ? "Excellent" : "Reduced", color: MarineColors.textSecondary)
                        WeatherDetailCard(icon: "thermometer.medium", label: "Temperature",
                                          value: "\(Int(weatherVM.current.temperature))",
                                          unit: "°C", subtext: "Feels comfortable", color: MarineColors.warningAmber)
                    }
                    .padding(.horizontal, 20)
                    
                    // Risks section
                    MarineCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RISK ASSESSMENT").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                            
                            RiskRow(label: "Wind Conditions",
                                    risk: weatherVM.current.windSpeed > 20 ? .high : weatherVM.current.windSpeed > 12 ? .medium : .low,
                                    detail: "\(Int(weatherVM.current.windSpeed)) knots from \(weatherVM.current.windDirection)")
                            RiskRow(label: "Wave Height",
                                    risk: weatherVM.current.waveHeight > 1.5 ? .high : weatherVM.current.waveHeight > 0.8 ? .medium : .low,
                                    detail: String(format: "%.1fm swell", weatherVM.current.waveHeight))
                            RiskRow(label: "Visibility",
                                    risk: weatherVM.current.visibility < 5 ? .high : weatherVM.current.visibility < 10 ? .medium : .low,
                                    detail: "\(Int(weatherVM.current.visibility)) km range")
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 100)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.3)) { appeared = true } }
    }
}

struct WeatherDetailCard: View {
    let icon: String; let label: String; let value: String; let unit: String; let subtext: String; var color: Color
    
    var body: some View {
        MarineCard(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
                    Text(label).font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary)
                }
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(value).font(MarineFont.mono(24, weight: .bold)).foregroundColor(.white)
                    Text(unit).font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary)
                }
                Text(subtext).font(MarineFont.body(11)).foregroundColor(color)
            }
        }
    }
}

enum RiskLevel { case low, medium, high }

struct RiskRow: View {
    let label: String
    let risk: RiskLevel
    let detail: String
    
    var riskColor: Color { risk == .low ? MarineColors.safeGreen : risk == .medium ? MarineColors.warningAmber : MarineColors.dangerRed }
    var riskLabel: String { risk == .low ? "Low" : risk == .medium ? "Moderate" : "High" }
    
    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(riskColor).frame(width: 8, height: 8)
            Text(label).font(MarineFont.body(13)).foregroundColor(.white)
            Spacer()
            Text(detail).font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary)
            Text(riskLabel).font(MarineFont.label(11)).foregroundColor(riskColor)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(riskColor.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Trip Log List (Screen 15)

struct TripLogListView: View {
    @EnvironmentObject var tripVM: TripLogViewModel
    @State private var showAddLog = false
    @State private var appeared = false
    
    var body: some View {
        NavigationView {
            ZStack {
                OceanBackground()
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LOGBOOK").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                            Text("Trip History").font(MarineFont.display(22, weight: .bold)).foregroundColor(.white)
                        }
                        Spacer()
                        Button { showAddLog = true } label: {
                            Image(systemName: "plus").font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black).frame(width: 36, height: 36)
                                .background(MarineGradients.aquaAccent).clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)
                    
                    if tripVM.logs.isEmpty {
                        Spacer()
                        EmptyStateView(icon: "book.closed.fill", title: "No Trips Logged", subtitle: "Your adventures will appear here")
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(tripVM.logs) { log in
                                    NavigationLink(destination: TripDetailView(log: log).environmentObject(tripVM)) {
                                        TripLogCard(log: log)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showAddLog) {
            AddTripLogView { log in tripVM.addLog(log) }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.3)) { appeared = true } }
    }
}

struct TripLogCard: View {
    let log: TripLog
    
    var body: some View {
        MarineCard(padding: 14) {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(log.routeName).font(MarineFont.label(15)).foregroundColor(.white).lineLimit(1)
                        Text(log.date, style: .date).font(MarineFont.body(12)).foregroundColor(MarineColors.textSecondary)
                    }
                    Spacer()
                    StarRating(rating: log.rating)
                }
                HStack(spacing: 12) {
                    TripMetricChip(icon: "arrow.left.and.right", value: String(format: "%.1f NM", log.distanceCovered), color: MarineColors.aquaGlow)
                    TripMetricChip(icon: "fuelpump.fill", value: String(format: "%.0fL", log.fuelUsed), color: MarineColors.fuelAmber)
                    TripMetricChip(icon: "clock.fill", value: String(format: "%.1fh", log.duration), color: MarineColors.routeGlow)
                    if log.photoCount > 0 {
                        TripMetricChip(icon: "photo.fill", value: "\(log.photoCount)", color: MarineColors.textSecondary)
                    }
                }
                if !log.notes.isEmpty {
                    Text(log.notes).font(MarineFont.body(12)).foregroundColor(MarineColors.textSecondary).lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct TripMetricChip: View {
    let icon: String; let value: String; var color: Color
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10)).foregroundColor(color)
            Text(value).font(MarineFont.mono(11, weight: .semibold)).foregroundColor(.white)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
    }
}

struct StarRating: View {
    let rating: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: 10))
                    .foregroundColor(i <= rating ? MarineColors.fuelAmber : MarineColors.textDim)
            }
        }
    }
}

// MARK: - Trip Detail View (Screen 16-17)

struct TripDetailView: View {
    let log: TripLog
    @EnvironmentObject var tripVM: TripLogViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            OceanBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button { presentationMode.wrappedValue.dismiss() } label: {
                            Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                                .foregroundColor(MarineColors.aquaGlow).frame(width: 36, height: 36)
                                .background(MarineColors.waterLayer).clipShape(Circle())
                        }
                        Spacer()
                        Text("Trip Details").font(MarineFont.label(16)).foregroundColor(.white)
                        Spacer()
                        Spacer().frame(width: 36)
                    }
                    .padding(.horizontal, 20).padding(.top, 16)
                    
                    // Route map
                    ZStack {
                        OceanMapView().frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 16))
                        BoatTopView(size: 40, glowColor: MarineColors.aquaGlow)
                    }
                    .padding(.horizontal, 20)
                    
                    // Trip info
                    MarineCard {
                        VStack(spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(log.routeName).font(MarineFont.display(18, weight: .bold)).foregroundColor(.white)
                                    Text(log.date, style: .date).font(MarineFont.body(13)).foregroundColor(MarineColors.textSecondary)
                                }
                                Spacer()
                                StarRating(rating: log.rating)
                            }
                            Divider().background(MarineColors.cardBorder)
                            HStack(spacing: 0) {
                                DetailStat(icon: "arrow.left.and.right", value: String(format: "%.1f", log.distanceCovered), unit: "NM", label: "Distance", color: MarineColors.aquaGlow)
                                DetailStat(icon: "fuelpump.fill", value: String(format: "%.0f", log.fuelUsed), unit: "L", label: "Fuel Used", color: MarineColors.fuelAmber)
                                DetailStat(icon: "clock.fill", value: String(format: "%.1f", log.duration), unit: "hr", label: "Duration", color: MarineColors.routeGlow)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Notes
                    if !log.notes.isEmpty {
                        MarineCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("NOTES").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                                Text(log.notes).font(MarineFont.body(14)).foregroundColor(.white).lineSpacing(4)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Photos placeholder
                    if log.photoCount > 0 {
                        MarineCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("PHOTOS (\(log.photoCount))").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    ForEach(0..<min(log.photoCount, 6), id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(MarineColors.waterLayer)
                                            .frame(height: 80)
                                            .overlay(Image(systemName: "photo").foregroundColor(MarineColors.textDim).font(.system(size: 20)))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Delete
                    Button {
                        tripVM.deleteLog(at: IndexSet(integer: tripVM.logs.firstIndex(where: { $0.id == log.id }) ?? 0))
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Label("Delete Trip", systemImage: "trash.fill")
                            .font(MarineFont.label(14))
                            .foregroundColor(MarineColors.dangerRed)
                            .frame(maxWidth: .infinity).frame(height: 44)
                            .background(MarineColors.dangerRed.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(MarineColors.dangerRed.opacity(0.2), lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 100)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct DetailStat: View {
    let icon: String; let value: String; let unit: String; let label: String; var color: Color
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(color)
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(MarineFont.mono(17, weight: .bold)).foregroundColor(.white)
                Text(unit).font(MarineFont.body(10)).foregroundColor(MarineColors.textSecondary)
            }
            Text(label).font(MarineFont.body(10)).foregroundColor(MarineColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Trip Log

struct AddTripLogView: View {
    var onSave: (TripLog) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var routeName = ""
    @State private var notes = ""
    @State private var distance = ""
    @State private var fuel = ""
    @State private var duration = ""
    @State private var rating = 4
    @State private var date = Date()
    
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
                        Text("Log a Trip").font(MarineFont.label(16)).foregroundColor(.white)
                        Spacer()
                        Button {
                            guard !routeName.isEmpty else { return }
                            let log = TripLog(id: UUID(), routeId: nil, routeName: routeName, date: date,
                                             distanceCovered: Double(distance) ?? 0,
                                             fuelUsed: Double(fuel) ?? 0,
                                             duration: Double(duration) ?? 0,
                                             notes: notes, photoCount: 0, rating: rating)
                            onSave(log)
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("Save").font(MarineFont.label(15)).foregroundColor(MarineColors.aquaGlow)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                    
                    MarineCard {
                        VStack(spacing: 16) {
                            MarineTextField(icon: "mappin.and.ellipse", placeholder: "Route / Trip name", text: $routeName)
                            DatePicker("Date", selection: $date, displayedComponents: .date)
                                .font(MarineFont.body(14)).foregroundColor(.white)
                                .colorScheme(.dark)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    MarineCard {
                        VStack(spacing: 12) {
                            FuelInputRow(icon: "arrow.left.and.right", label: "Distance (NM)", value: $distance, keyboardType: .decimalPad)
                            FuelInputRow(icon: "fuelpump.fill", label: "Fuel Used (L)", value: $fuel, keyboardType: .decimalPad)
                            FuelInputRow(icon: "clock.fill", label: "Duration (hrs)", value: $duration, keyboardType: .decimalPad)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    MarineCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("RATING").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { i in
                                    Button { rating = i } label: {
                                        Image(systemName: i <= rating ? "star.fill" : "star")
                                            .font(.system(size: 28)).foregroundColor(i <= rating ? MarineColors.fuelAmber : MarineColors.textDim)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    MarineCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOTES").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                            TextEditor(text: $notes)
                                .font(MarineFont.body(14))
                                .foregroundColor(.white)
                                .frame(minHeight: 80)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 80)
                }
            }
        }
    }
}

// MARK: - Analytics View (Screens 18-20)

struct AnalyticsView: View {
    @EnvironmentObject var tripVM: TripLogViewModel
    @EnvironmentObject var routeVM: RouteViewModel
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            OceanBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ANALYTICS").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                            Text("Your Stats").font(MarineFont.display(22, weight: .bold)).foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                    
                    // Big numbers
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        BigStatCard(icon: "arrow.left.and.right", value: String(format: "%.1f", tripVM.totalDistance),
                                    unit: "NM", label: "Total Distance", color: MarineColors.aquaGlow)
                        BigStatCard(icon: "fuelpump.fill", value: String(format: "%.0f", tripVM.totalFuel),
                                    unit: "L", label: "Total Fuel", color: MarineColors.fuelAmber)
                        BigStatCard(icon: "clock.fill", value: String(format: "%.1f", tripVM.totalHours),
                                    unit: "hrs", label: "On Water", color: MarineColors.routeGlow)
                        BigStatCard(icon: "map.fill", value: "\(tripVM.logs.count)",
                                    unit: "trips", label: "Total Trips", color: MarineColors.safeGreen)
                    }
                    .padding(.horizontal, 20)
                    
                    // Efficiency
                    MarineCard {
                        VStack(spacing: 14) {
                            Text("FUEL EFFICIENCY").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text(String(format: "%.1f", tripVM.avgEfficiency))
                                    .font(MarineFont.mono(40, weight: .black)).foregroundColor(.white)
                                Text("L/NM").font(MarineFont.body(16)).foregroundColor(MarineColors.textSecondary)
                            }
                            Text("Average fuel consumption per nautical mile")
                                .font(MarineFont.body(12)).foregroundColor(MarineColors.textSecondary)
                            
                            // Bar graph (simple)
                            VStack(spacing: 8) {
                                ForEach(tripVM.logs.prefix(4)) { log in
                                    AnalyticsBar(label: log.routeName, value: log.fuelUsed / max(log.distanceCovered, 0.1),
                                                 maxValue: 5, color: MarineColors.fuelOrange)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Trip history bars
                    MarineCard {
                        VStack(spacing: 12) {
                            Text("DISTANCE PER TRIP").font(MarineFont.mono(10)).foregroundColor(MarineColors.textDim)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            let maxDist = tripVM.logs.map(\.distanceCovered).max() ?? 1
                            ForEach(tripVM.logs.prefix(5)) { log in
                                AnalyticsBar(label: log.routeName, value: log.distanceCovered,
                                             maxValue: maxDist, color: MarineColors.aquaGlow)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer().frame(height: 100)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear { withAnimation(.easeOut(duration: 0.3)) { appeared = true } }
    }
}

struct BigStatCard: View {
    let icon: String; let value: String; let unit: String; let label: String; var color: Color
    
    var body: some View {
        MarineCard(padding: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(color)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(value).font(MarineFont.mono(24, weight: .black)).foregroundColor(.white)
                        Text(unit).font(MarineFont.body(12)).foregroundColor(MarineColors.textSecondary)
                    }
                    Text(label).font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary)
                }
            }
        }
    }
}

struct AnalyticsBar: View {
    let label: String; let value: Double; let maxValue: Double; var color: Color
    @State private var appeared = false
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label).font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary).lineLimit(1)
                Spacer()
                Text(String(format: "%.1f", value)).font(MarineFont.mono(11, weight: .bold)).foregroundColor(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(MarineColors.waterLayer).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: appeared ? geo.size.width * CGFloat(value / max(maxValue, 0.1)) : 0, height: 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1), value: appeared)
                }
            }
            .frame(height: 6)
        }
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { appeared = true } }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String; let title: String; let subtitle: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 40)).foregroundColor(MarineColors.textDim)
            Text(title).font(MarineFont.label(18)).foregroundColor(.white)
            Text(subtitle).font(MarineFont.body(14)).foregroundColor(MarineColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}
