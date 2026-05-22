import SwiftUI

// MARK: - Color System
extension Color {
    // Backgrounds
    static let roadDark     = Color(hex: "#0F172A")
    static let nightBg      = Color(hex: "#111827")
    static let cardBg       = Color(hex: "#1E293B")
    static let cardBg2      = Color(hex: "#243047")

    // Accents
    static let cctv         = Color(hex: "#22D3EE")   // road lines / CCTV
    static let warning      = Color(hex: "#FACC15")   // warning
    static let activeFlow   = Color(hex: "#F97316")   // active traffic
    static let freeRoad     = Color(hex: "#22C55E")   // free road
    static let congestion   = Color(hex: "#EF4444")   // traffic jam

    // Text
    static let textPrimary  = Color(hex: "#F8FAFC")
    static let textSecondary = Color(hex: "#CBD5E1")
    static let textMuted    = Color(hex: "#64748B")

    // Buttons
    static let btnPrimary   = Color(hex: "#22D3EE")
    static let btnSecondary = Color(hex: "#1E293B")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Typography
struct AppFont {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func headline(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat = 15) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func caption(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
    static func mono(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

// MARK: - Spacing
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let xxl: CGFloat = 40
}

// MARK: - Corner Radius
enum Radius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 18
    static let xl: CGFloat = 24
    static let pill: CGFloat = 100
}

// MARK: - Animations
extension Animation {
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let springFast = Animation.spring(response: 0.3, dampingFraction: 0.75)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
}

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.springFast, value: configuration.isPressed)
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(AppFont.headline(15))
            }
            .foregroundColor(.nightBg)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [.cctv, Color(hex: "#06B6D4")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(Radius.md)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(title)
                    .font(AppFont.headline(14))
            }
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.cardBg)
            .cornerRadius(Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(Color.cctv.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Card View
struct AppCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .background(Color.cardBg)
            .cornerRadius(Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .stroke(Color.cctv.opacity(0.12), lineWidth: 1)
            )
    }
}

// MARK: - Traffic Score Color
func trafficColor(_ score: Int) -> Color {
    switch score {
    case 0..<40: return .congestion
    case 40..<70: return .warning
    default: return .freeRoad
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AppFont.caption(10))
            .foregroundColor(.nightBg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .cornerRadius(Radius.pill)
    }
}

// MARK: - Grid Line Pattern (CCTV Effect)
struct GridPattern: View {
    var body: some View {
        Canvas { ctx, size in
            let spacing: CGFloat = 40
            var xPath = Path()
            var x: CGFloat = 0
            while x <= size.width {
                xPath.move(to: CGPoint(x: x, y: 0))
                xPath.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }
            var yPath = Path()
            var y: CGFloat = 0
            while y <= size.height {
                yPath.move(to: CGPoint(x: 0, y: y))
                yPath.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            ctx.stroke(xPath, with: .color(.cctv.opacity(0.06)), lineWidth: 0.5)
            ctx.stroke(yPath, with: .color(.cctv.opacity(0.06)), lineWidth: 0.5)
        }
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: phase - 0.3),
                        .init(color: .white.opacity(0.15), location: phase),
                        .init(color: .clear, location: phase + 0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.3
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Scan Line Overlay (CCTV)
struct ScanLineOverlay: View {
    @State private var scanY: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .cctv.opacity(0.08), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 60)
                .offset(y: scanY)
                .onAppear {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        scanY = geo.size.height
                    }
                }
        }
        .clipped()
        .allowsHitTesting(false)
    }
}
