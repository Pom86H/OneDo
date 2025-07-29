import SwiftUI

struct LaunchScreenView: View {
    // MARK: - Get system color scheme
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - State variables to manage animation
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.8
    
    // MARK: - Closure to notify parent view when animation is complete
    var onAnimationComplete: () -> Void

    // MARK: - Custom color definitions (synchronized with ContentView)
    var customAccentColor: Color {
        // Light: #D48C45, Dark: #F5B070 (Warm Orange/Brown)
        colorScheme == .dark ? Color(red: 0xF5/255.0, green: 0xB0/255.0, blue: 0x70/255.0) : Color(red: 0xD4/255.0, green: 0x8C/255.0, blue: 0x45/255.0)
    }
    var customBaseColor: Color {
        // Light: #FDF8F0, Dark: #2A2A2A (Soft Off-white / Dark Gray)
        colorScheme == .dark ? Color(red: 0x2A/255.0, green: 0x2A/255.0, blue: 0x2A/255.0) : Color(red: 0xFD/255.0, green: 0xF8/255.0, blue: 0xF0/255.0)
    }
    var customTextColor: Color {
        // Light: #544739, Dark: #E0DCD7 (Dark Brown / Light Warm Gray)
        colorScheme == .dark ? Color(red: 0xE0/255.0, green: 0xDC/255.0, blue: 0xD7/255.0) : Color(red: 0x54/255.0, green: 0x47/255.0, blue: 0x39/255.0)
    }

    var body: some View {
        ZStack {
            // MARK: - Set background color to custom base color
            customBaseColor.edgesIgnoringSafeArea(.all)

            VStack {
                // MARK: - App icon (dog paw print)
                Image(systemName: "pawprint.fill") // Changed to pawprint.fill
                    .font(.system(size: 80)) // Icon size
                    .foregroundColor(customAccentColor) // Apply accent color
                    .scaleEffect(scale) // Scale animation
                    .opacity(opacity) // Fade animation
                    .animation(.easeOut(duration: 1.0), value: scale) // Speed of scale animation

                // MARK: - App name text
                Text("OneDo")
                    .font(.largeTitle) // Font size
                    .fontWeight(.bold) // Font weight
                    .foregroundColor(customTextColor) // Apply text color
                    .scaleEffect(scale) // スケールアニメーション
                    .opacity(opacity) // フェードアニメーション
                    .animation(.easeOut(duration: 1.0), value: scale) // スケールアニメーションの速度
            }
        }
        // MARK: - Trigger animation and transition when view appears
        .onAppear {
            // Fade in and scale up animation
            withAnimation {
                self.opacity = 1.0
                self.scale = 1.0
            }
            // After animation display, wait a bit then fade out and notify parent view
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { // Display for 1.5 seconds
                withAnimation {
                    self.opacity = 0.0 // フェードアウト
                    self.scale = 1.2 // Slightly enlarge during fade out
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Wait for fade out
                    onAnimationComplete() // Notify parent view of animation completion
                }
            }
        }
    }
}

// MARK: - Preview (commented out to avoid review errors)
// #Preview {
//     LaunchScreenView(onAnimationComplete: {})
// }
