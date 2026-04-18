import SwiftUI

// MARK: - Color Palette

struct MarineColors {
    // Deep ocean backgrounds
    static let deepOcean = Color(hex: "#040D1A")
    static let oceanMid = Color(hex: "#071629")
    static let oceanSurface = Color(hex: "#0B2040")
    static let waterLayer = Color(hex: "#0D2B52")
    
    // Accent — electric aqua / bioluminescence
    static let aquaGlow = Color(hex: "#00D4FF")
    static let aquaDim = Color(hex: "#0099CC")
    static let aquaDeep = Color(hex: "#005F80")
    
    // Navigation / route line
    static let routeGlow = Color(hex: "#00FFB3")
    static let routeDim = Color(hex: "#00CC8E")
    
    // Fuel / energy
    static let fuelOrange = Color(hex: "#FF6B2B")
    static let fuelAmber = Color(hex: "#FFB020")
    
    // Status
    static let safeGreen = Color(hex: "#00E87A")
    static let warningAmber = Color(hex: "#FFB020")
    static let dangerRed = Color(hex: "#FF3B5C")
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#7FB3CC")
    static let textDim = Color(hex: "#3A6A88")
    
    // Cards
    static let cardBase = Color(hex: "#071629").opacity(0.9)
    static let cardBorder = Color(hex: "#0D3A5C")
    static let cardHighlight = Color(hex: "#00D4FF").opacity(0.08)
    
    // Light mode overrides
    static let lightBackground = Color(hex: "#E8F4FA")
    static let lightCard = Color.white
    static let lightText = Color(hex: "#0B2040")
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a,r,g,b) = (255,(int>>8)*17,(int>>4&0xF)*17,(int&0xF)*17)
        case 6: (a,r,g,b) = (255,int>>16,int>>8&0xFF,int&0xFF)
        case 8: (a,r,g,b) = (int>>24,int>>16&0xFF,int>>8&0xFF,int&0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Gradient Library

struct MarineGradients {
    static let oceanDepth = LinearGradient(
        colors: [MarineColors.deepOcean, MarineColors.oceanMid],
        startPoint: .top, endPoint: .bottom)
    
    static let cardGlow = LinearGradient(
        colors: [MarineColors.cardHighlight, Color.clear],
        startPoint: .topLeading, endPoint: .bottomTrailing)
    
    static let aquaAccent = LinearGradient(
        colors: [MarineColors.aquaGlow, MarineColors.aquaDim],
        startPoint: .leading, endPoint: .trailing)
    
    static let routeLine = LinearGradient(
        colors: [MarineColors.routeGlow, MarineColors.aquaGlow],
        startPoint: .leading, endPoint: .trailing)
    
    static let fuelGradient = LinearGradient(
        colors: [MarineColors.fuelOrange, MarineColors.fuelAmber],
        startPoint: .leading, endPoint: .trailing)
    
    static let safeGradient = LinearGradient(
        colors: [MarineColors.safeGreen, MarineColors.routeDim],
        startPoint: .leading, endPoint: .trailing)
    
    static let dangerGradient = LinearGradient(
        colors: [MarineColors.dangerRed, MarineColors.fuelOrange],
        startPoint: .leading, endPoint: .trailing)
}

// MARK: - Typography

struct MarineFont {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    static func label(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Reusable Components

struct MarineCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var hasBorder: Bool = true
    
    init(padding: CGFloat = 16, hasBorder: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
        self.hasBorder = hasBorder
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(MarineColors.cardBase)
            if hasBorder {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(MarineColors.cardBorder, lineWidth: 1)
            }
            RoundedRectangle(cornerRadius: 16)
                .fill(MarineGradients.cardGlow)
            content.padding(padding)
        }
    }
}

struct MarinePrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isLoading: Bool = false
    
    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isLoading = isLoading
    }
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { isPressed = false; action() } }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.black).scaleEffect(0.8)
                } else {
                    if let icon = icon { Image(systemName: icon).font(.system(size: 16, weight: .semibold)) }
                    Text(title).font(MarineFont.label(16))
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(MarineGradients.aquaAccent)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

struct MarineSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = true }; DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { isPressed = false; action() } }) {
            HStack(spacing: 8) {
                if let icon = icon { Image(systemName: icon).font(.system(size: 15, weight: .semibold)) }
                Text(title).font(MarineFont.label(15))
            }
            .foregroundColor(MarineColors.aquaGlow)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(MarineColors.aquaGlow.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(MarineColors.aquaGlow.opacity(0.4), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    var color: Color = MarineColors.aquaGlow
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 11)).foregroundColor(color)
                Text(value).font(MarineFont.mono(16, weight: .bold)).foregroundColor(.white)
            }
            Text(label).font(MarineFont.body(11)).foregroundColor(MarineColors.textSecondary)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(color.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.2), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct GlowDot: View {
    var color: Color = MarineColors.safeGreen
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Circle().fill(color.opacity(0.2)).frame(width: 18, height: 18)
                .scaleEffect(pulse ? 1.5 : 1.0).opacity(pulse ? 0 : 0.6)
            Circle().fill(color).frame(width: 8, height: 8)
        }
        .onAppear { withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) { pulse = true } }
    }
}

// MARK: - Top-down Boat Illustration

struct BoatTopView: View {
    var size: CGFloat = 60
    var glowColor: Color = MarineColors.aquaGlow
    @State private var rotate = false
    @State private var bobbing = false
    
    var body: some View {
        ZStack {
            // Wake rings
            ForEach(0..<3) { i in
                Ellipse()
                    .stroke(glowColor.opacity(0.06 * Double(3 - i)), lineWidth: 1)
                    .frame(width: size * (1.2 + Double(i) * 0.3), height: size * (0.4 + Double(i) * 0.1))
                    .offset(y: size * 0.25)
            }
            
            // Hull
            ZStack {
                Capsule()
                    .fill(LinearGradient(colors: [Color(hex: "#1A3A5C"), Color(hex: "#0D2540")],
                                        startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.38, height: size)
                
                // Cabin
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [Color(hex: "#2A5A80"), Color(hex: "#1A3A5C")],
                                        startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.24, height: size * 0.32)
                    .offset(y: -size * 0.05)
                
                // Windows
                HStack(spacing: size * 0.06) {
                    ForEach(0..<2) { _ in
                        Circle().fill(glowColor.opacity(0.8)).frame(width: size * 0.05, height: size * 0.05)
                    }
                }
                .offset(y: -size * 0.05)
                
                // Bow point
                Triangle()
                    .fill(LinearGradient(colors: [Color(hex: "#1A3A5C"), Color(hex: "#0D2540")],
                                        startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.38, height: size * 0.18)
                    .offset(y: -size * 0.56)
                
                // Center line
                Rectangle()
                    .fill(glowColor.opacity(0.15))
                    .frame(width: 1, height: size * 0.6)
                    .offset(y: size * 0.08)
            }
            .shadow(color: glowColor.opacity(0.25), radius: 12, x: 0, y: 0)
        }
        .offset(y: bobbing ? -2 : 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) { bobbing = true }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Ocean Background

struct OceanBackground: View {
    @State private var wave1: CGFloat = 0
    @State private var wave2: CGFloat = 0
    
    var body: some View {
        ZStack {
            MarineColors.deepOcean.ignoresSafeArea()
            
            // Subtle grid
            GeometryReader { geo in
                let cols = Int(geo.size.width / 40) + 1
                let rows = Int(geo.size.height / 40) + 1
                ForEach(0..<cols, id: \.self) { col in
                    ForEach(0..<rows, id: \.self) { row in
                        Rectangle()
                            .fill(MarineColors.aquaGlow.opacity(0.025))
                            .frame(width: 1, height: 40)
                            .position(x: CGFloat(col) * 40, y: CGFloat(row) * 40)
                    }
                }
                ForEach(0..<rows, id: \.self) { row in
                    Rectangle()
                        .fill(MarineColors.aquaGlow.opacity(0.025))
                        .frame(width: geo.size.width, height: 1)
                        .position(x: geo.size.width/2, y: CGFloat(row) * 40)
                }
            }
            
            // Radial depth gradient
            RadialGradient(
                colors: [MarineColors.aquaGlow.opacity(0.04), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 300)
            .ignoresSafeArea()
        }
    }
}

// MARK: - Route Path View

struct RoutePathView: View {
    var waypoints: [(Double, Double)]
    var animated: Bool = true
    @State private var dashPhase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            if waypoints.count >= 2 {
                ZStack {
                    // Glow path
                    Path { path in
                        let pts = normalizedPoints(in: geo.size)
                        path.move(to: pts[0])
                        for pt in pts.dropFirst() { path.addLine(to: pt) }
                    }
                    .stroke(MarineColors.routeGlow.opacity(0.3), lineWidth: 6)
                    .blur(radius: 4)
                    
                    // Main path
                    Path { path in
                        let pts = normalizedPoints(in: geo.size)
                        path.move(to: pts[0])
                        for pt in pts.dropFirst() { path.addLine(to: pt) }
                    }
                    .stroke(
                        LinearGradient(colors: [MarineColors.routeGlow, MarineColors.aquaGlow],
                                       startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4], dashPhase: dashPhase)
                    )
                    
                    // Waypoint dots
                    ForEach(0..<normalizedPoints(in: geo.size).count, id: \.self) { i in
                        let pt = normalizedPoints(in: geo.size)[i]
                        ZStack {
                            Circle().fill(i == 0 ? MarineColors.safeGreen : (i == waypoints.count - 1 ? MarineColors.dangerRed : MarineColors.aquaGlow))
                                .frame(width: 10, height: 10)
                            Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                                .frame(width: 10, height: 10)
                        }
                        .position(x: pt.x, y: pt.y)
                    }
                }
                .onAppear {
                    if animated {
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            dashPhase -= 24
                        }
                    }
                }
            }
        }
    }
    
    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        let lats = waypoints.map { $0.0 }
        let lons = waypoints.map { $0.1 }
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        let latRange = max(maxLat - minLat, 0.01)
        let lonRange = max(maxLon - minLon, 0.01)
        
        return waypoints.map { wp in
            let x = (wp.1 - minLon) / lonRange * (size.width * 0.8) + size.width * 0.1
            let y = (1 - (wp.0 - minLat) / latRange) * (size.height * 0.8) + size.height * 0.1
            return CGPoint(x: x, y: y)
        }
    }
}
