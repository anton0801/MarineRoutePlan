import SwiftUI

// MARK: - Launch / Splash Screen

struct LaunchView: View {
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.2
    @State private var ringOpacity: Double = 0.8
    @State private var waveOffset: CGFloat = 400
    @State private var textOpacity: Double = 0
    @State private var glowIntensity: Double = 0
    @Binding var isFinished: Bool
    
    var body: some View {
        ZStack {
            OceanBackground()
            
            // Expanding rings
            ForEach(0..<4) { i in
                Circle()
                    .stroke(MarineColors.aquaGlow.opacity(ringOpacity * Double(4-i) * 0.08), lineWidth: 1)
                    .frame(width: 80 + CGFloat(i) * 60, height: 80 + CGFloat(i) * 60)
                    .scaleEffect(ringScale)
            }
            
            // Water wave sweep
            WaveSweepShape(offset: waveOffset)
                .fill(MarineColors.aquaGlow.opacity(0.06))
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo mark
                ZStack {
                    Circle()
                        .fill(MarineColors.aquaGlow.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Circle()
                        .stroke(MarineGradients.aquaAccent, lineWidth: 1.5)
                        .frame(width: 100, height: 100)
                    BoatTopView(size: 52, glowColor: MarineColors.aquaGlow)
                }
                .shadow(color: MarineColors.aquaGlow.opacity(glowIntensity), radius: 30)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                VStack(spacing: 6) {
                    Text("MARINE")
                        .font(MarineFont.display(28, weight: .black))
                        .tracking(8)
                        .foregroundColor(.white)
                    Text("ROUTE PLAN")
                        .font(MarineFont.display(13, weight: .medium))
                        .tracking(6)
                        .foregroundColor(MarineColors.aquaGlow)
                }
                .opacity(textOpacity)
            }
        }
        .onAppear { animate() }
    }
    
    private func animate() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.65).delay(0.2)) {
            logoScale = 1.0; logoOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 1.2).delay(0.1)) {
            ringScale = 1.0
        }
        withAnimation(.easeOut(duration: 1.0).delay(0.6)) {
            waveOffset = -400
        }
        withAnimation(.easeIn(duration: 0.6).delay(0.7)) {
            textOpacity = 1.0
        }
        withAnimation(.easeInOut(duration: 1.5).delay(0.5)) {
            glowIntensity = 0.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeInOut(duration: 0.4)) { isFinished = false }
        }
    }
}

struct WaveSweepShape: Shape {
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + offset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + offset + 200, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + offset + 100, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + offset - 100, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            OceanBackground()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    OnboardingPage1().tag(0)
                    OnboardingPage2().tag(1)
                    OnboardingPage3().tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)
                
                // Controls
                VStack(spacing: 20) {
                    // Dot indicators
                    HStack(spacing: 8) {
                        ForEach(0..<3) { i in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(i == currentPage ? MarineColors.aquaGlow : MarineColors.textDim)
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        if currentPage < 2 {
                            Button("Skip") {
                                withAnimation { appState.hasCompletedOnboarding = true }
                            }
                            .font(MarineFont.body(15))
                            .foregroundColor(MarineColors.textSecondary)
                            .frame(width: 70)
                            
                            MarinePrimaryButton("Next", icon: "arrow.right") {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { currentPage += 1 }
                            }
                        } else {
                            MarinePrimaryButton("Get Started", icon: "sailboat.fill") {
                                withAnimation { appState.hasCompletedOnboarding = true }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 48)
            }
        }
    }
}

struct OnboardingPage1: View {
    @State private var appeared = false
    @State private var boatOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Illustration area
            ZStack {
                // Water grid
                GridPatternView()
                    .frame(height: 320)
                    .clipped()
                
                // Animated boat
                BoatTopView(size: 80, glowColor: MarineColors.aquaGlow)
                    .offset(y: boatOffset)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.5)
                
                // Compass rose
                CompassRoseView()
                    .frame(width: 80, height: 80)
                    .position(x: UIScreen.main.bounds.width * 0.8, y: 80)
                    .opacity(appeared ? 0.4 : 0)
            }
            .frame(height: 320)
            
            VStack(spacing: 16) {
                Text("Plan Your Route\non Water")
                    .font(MarineFont.display(32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                
                Text("Chart your journey with precision.\nSee your path from above.")
                    .font(MarineFont.body(16))
                    .foregroundColor(MarineColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.2)) {
                appeared = true
            }
        }
    }
}

struct OnboardingPage2: View {
    @State private var appeared = false
    @State private var lineProgress: CGFloat = 0
    @State private var fuelLevel: CGFloat = 0.75
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                GridPatternView().frame(height: 320).clipped()
                
                // Route line animation
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    Path { path in
                        path.move(to: CGPoint(x: w*0.15, y: h*0.7))
                        path.addCurve(to: CGPoint(x: w*0.85, y: h*0.3),
                                      control1: CGPoint(x: w*0.35, y: h*0.2),
                                      control2: CGPoint(x: w*0.65, y: h*0.6))
                    }
                    .trim(from: 0, to: lineProgress)
                    .stroke(MarineGradients.routeLine, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    
                    // Start/End points
                    if lineProgress > 0.1 {
                        Circle().fill(MarineColors.safeGreen).frame(width: 12, height: 12)
                            .position(x: w*0.15, y: h*0.7)
                    }
                    if lineProgress > 0.9 {
                        Circle().fill(MarineColors.aquaGlow).frame(width: 12, height: 12)
                            .position(x: w*0.85, y: h*0.3)
                    }
                }
                
                // Fuel gauge card
                VStack(spacing: 6) {
                    Text("FUEL").font(MarineFont.mono(10)).foregroundColor(MarineColors.textSecondary)
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(MarineColors.waterLayer)
                            .frame(width: 80, height: 8)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(MarineGradients.fuelGradient)
                            .frame(width: 80 * fuelLevel, height: 8)
                    }
                    Text("\(Int(fuelLevel * 100))%").font(MarineFont.mono(12, weight: .bold)).foregroundColor(MarineColors.fuelAmber)
                }
                .padding(10)
                .background(MarineColors.cardBase)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(MarineColors.cardBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .offset(x: 60, y: 70)
                .opacity(appeared ? 1 : 0)
            }
            .frame(height: 320)
            
            VStack(spacing: 16) {
                Text("Calculate Fuel\n& Time")
                    .font(MarineFont.display(32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                
                Text("Know exactly how much fuel you need.\nOptimize every journey.")
                    .font(MarineFont.body(16))
                    .foregroundColor(MarineColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).delay(0.2)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.5).delay(0.4)) { lineProgress = 1.0 }
        }
    }
}

struct OnboardingPage3: View {
    @State private var appeared = false
    @State private var pulse = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                GridPatternView().frame(height: 320).clipped()
                
                // Sonar rings
                ForEach(0..<5) { i in
                    Circle()
                        .stroke(MarineColors.safeGreen.opacity(0.15 * Double(5-i)), lineWidth: 1)
                        .frame(width: 40 + CGFloat(i) * 50, height: 40 + CGFloat(i) * 50)
                        .scaleEffect(pulse ? 1.05 : 0.95)
                        .animation(.easeInOut(duration: 1.5 + Double(i) * 0.2).repeatForever(autoreverses: true), value: pulse)
                }
                
                // Moving boat
                BoatTopView(size: 60, glowColor: MarineColors.safeGreen)
                    .opacity(appeared ? 1 : 0)
                
                // Status chips
                VStack(spacing: 0) {
                    HStack {
                        StatusChip(icon: "wind", label: "12 kn", color: MarineColors.safeGreen)
                        Spacer()
                    }
                    .padding(.leading, 30)
                    .offset(y: -50)
                    
                    HStack {
                        Spacer()
                        StatusChip(icon: "water.waves", label: "0.5m", color: MarineColors.aquaGlow)
                    }
                    .padding(.trailing, 30)
                    .offset(y: 40)
                }
                .opacity(appeared ? 1 : 0)
            }
            .frame(height: 320)
            
            VStack(spacing: 16) {
                Text("Navigate\nSmarter")
                    .font(MarineFont.display(32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                
                Text("Live weather, wind, and wave data.\nAlways know the conditions.")
                    .font(MarineFont.body(16))
                    .foregroundColor(MarineColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(appeared ? 1 : 0)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) { appeared = true }
            withAnimation(.easeInOut(duration: 1.5).delay(0.3)) { pulse = true }
        }
    }
}

struct StatusChip: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold)).foregroundColor(color)
            Text(label).font(MarineFont.mono(12, weight: .bold)).foregroundColor(.white)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(MarineColors.cardBase)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct GridPatternView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                MarineColors.deepOcean
                
                // Water shimmer lines
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(MarineColors.aquaGlow.opacity(0.03 + Double(i % 3) * 0.01))
                        .frame(height: 1)
                        .offset(y: CGFloat(i) * (geo.size.height / 8))
                }
            }
        }
    }
}

struct CompassRoseView: View {
    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Rectangle()
                    .fill(MarineColors.aquaGlow.opacity(0.3))
                    .frame(width: 1, height: 20)
                    .offset(y: -30)
                    .rotationEffect(.degrees(Double(i) * 45))
            }
            Circle().stroke(MarineColors.aquaGlow.opacity(0.2), lineWidth: 1).frame(width: 50, height: 50)
            Text("N").font(MarineFont.label(10)).foregroundColor(MarineColors.aquaGlow)
                .offset(y: -28)
        }
    }
}
