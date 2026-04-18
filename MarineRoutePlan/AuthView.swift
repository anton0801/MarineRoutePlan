import SwiftUI

// MARK: - Auth / Login View

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var appeared = false
    
    var body: some View {
        ZStack {
            OceanBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Logo area
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(MarineColors.aquaGlow.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Circle()
                                .stroke(MarineGradients.aquaAccent, lineWidth: 1.5)
                                .frame(width: 80, height: 80)
                            BoatTopView(size: 44, glowColor: MarineColors.aquaGlow)
                        }
                        
                        VStack(spacing: 4) {
                            Text("MARINE ROUTE PLAN")
                                .font(MarineFont.display(16, weight: .black))
                                .tracking(4)
                                .foregroundColor(.white)
                            Text(isSignUp ? "Create Account" : "Welcome Back")
                                .font(MarineFont.body(14))
                                .foregroundColor(MarineColors.textSecondary)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -20)
                    
                    // Form card
                    MarineCard(padding: 24) {
                        VStack(spacing: 16) {
                            if isSignUp {
                                MarineTextField(icon: "person", placeholder: "Full Name", text: $name)
                            }
                            MarineTextField(icon: "envelope", placeholder: "Email", text: $email, keyboardType: .emailAddress)
                            MarineTextField(icon: "lock", placeholder: "Password", text: $password, isSecure: true)
                            
                            if showError {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(MarineColors.dangerRed)
                                        .font(.system(size: 12))
                                    Text(errorMessage)
                                        .font(MarineFont.body(13))
                                        .foregroundColor(MarineColors.dangerRed)
                                }
                                .padding(.horizontal, 4)
                            }
                            
                            MarinePrimaryButton(isSignUp ? "Create Account" : "Sign In",
                                               icon: isSignUp ? "person.badge.plus" : "arrow.right.circle",
                                               isLoading: isLoading) {
                                handleAuth()
                            }
                            
                            Button(action: { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isSignUp.toggle(); showError = false } }) {
                                Text(isSignUp ? "Already have an account? " : "Don't have an account? ")
                                    .foregroundColor(MarineColors.textSecondary)
                                + Text(isSignUp ? "Sign In" : "Sign Up")
                                    .foregroundColor(MarineColors.aquaGlow)
                            }
                            .font(MarineFont.body(14))
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    
                    // Divider
                    HStack(spacing: 12) {
                        Rectangle().fill(MarineColors.cardBorder).frame(height: 1)
                        Text("or").font(MarineFont.body(13)).foregroundColor(MarineColors.textDim)
                        Rectangle().fill(MarineColors.cardBorder).frame(height: 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .opacity(appeared ? 1 : 0)
                    
                    // Demo Account — prominently visible
                    VStack(spacing: 10) {
                        MarineCard(padding: 20) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(MarineColors.fuelAmber.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "sailboat.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(MarineColors.fuelAmber)
                                }
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Try Demo Account")
                                        .font(MarineFont.label(15))
                                        .foregroundColor(.white)
                                    Text("Explore all features instantly")
                                        .font(MarineFont.body(12))
                                        .foregroundColor(MarineColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(MarineColors.fuelAmber)
                            }
                        }
                        .onTapGesture { appState.loginAsDemo() }
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(MarineColors.fuelAmber.opacity(0.3), lineWidth: 1.5)
                        )
                        
                        Text("demo@marineroute.app • no sign up needed")
                            .font(MarineFont.body(12))
                            .foregroundColor(MarineColors.textDim)
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    
                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) { appeared = true }
        }
    }
    
    private func handleAuth() {
        showError = false
        if isSignUp {
            guard !name.isEmpty else { errorMessage = "Please enter your name."; showError = true; return }
        }
        guard email.contains("@") else { errorMessage = "Please enter a valid email."; showError = true; return }
        guard password.count >= 6 else { errorMessage = "Password must be at least 6 characters."; showError = true; return }
        
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            appState.userName = isSignUp ? name : email.components(separatedBy: "@").first?.capitalized ?? "Captain"
            appState.userEmail = email
            appState.isLoggedIn = true
        }
    }
}

struct MarineTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    @State private var isFocused = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isFocused ? MarineColors.aquaGlow : MarineColors.textDim)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(MarineFont.body(15))
                    .foregroundColor(.white)
                    .accentColor(MarineColors.aquaGlow)
            } else {
                TextField(placeholder, text: $text)
                    .font(MarineFont.body(15))
                    .foregroundColor(.white)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .accentColor(MarineColors.aquaGlow)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(MarineColors.waterLayer.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused ? MarineColors.aquaGlow.opacity(0.5) : MarineColors.cardBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
