import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompleted = false
    @State private var currentPage = 0
    @State private var isVisible = true

    var body: some View {
        ZStack {
            Color.roadDark.ignoresSafeArea()
            GridPattern().ignoresSafeArea().opacity(0.5)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        withAnimation(.spring) { hasCompleted = true }
                    }
                    .font(AppFont.body(14))
                    .foregroundColor(.textMuted)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // Pages
                TabView(selection: $currentPage) {
                    OnboardPage1(isVisible: $isVisible) { advance() }
                        .tag(0)
                    OnboardPage2(isVisible: $isVisible) { advance() }
                        .tag(1)
                    OnboardPage3(isVisible: $isVisible) { complete() }
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring, value: currentPage)

                // Page indicators + Next
                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? Color.cctv : Color.textMuted.opacity(0.3))
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring, value: currentPage)
                        }
                    }

                    PrimaryButton(currentPage < 2 ? "Next" : "Get Started",
                                  icon: currentPage < 2 ? "arrow.right" : "checkmark") {
                        if currentPage < 2 { advance() } else { complete() }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
        .onDisappear { isVisible = false }
    }

    private func advance() {
        withAnimation(.spring) { currentPage = min(currentPage + 1, 2) }
    }

    private func complete() {
        withAnimation(.easeIn(duration: 0.3)) { hasCompleted = true }
    }
}

// MARK: - Page 1: Tap to burst
struct OnboardPage1: View {
    @Binding var isVisible: Bool
    let onNext: () -> Void

    @State private var tapped = false
    @State private var particles: [(id: UUID, offset: CGSize, color: Color, scale: CGFloat)] = []
    @State private var iconScale: CGFloat = 1.0
    @State private var iconGlow: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Interactive illustration
            ZStack {
                // Background glow
                Circle()
                    .fill(Color.cctv.opacity(0.08))
                    .frame(width: 220, height: 220)

                Circle()
                    .stroke(Color.cctv.opacity(0.2), lineWidth: 1)
                    .frame(width: 180, height: 180)

                // Particles
                ForEach(particles, id: \.id) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: 6 * p.scale, height: 6 * p.scale)
                        .offset(p.offset)
                        .opacity(tapped ? 0 : 1)
                }

                // Main icon
                ZStack {
                    Circle()
                        .fill(Color.cardBg)
                        .frame(width: 110, height: 110)
                    Circle()
                        .stroke(Color.cctv.opacity(0.4 + iconGlow * 0.6), lineWidth: 2)
                        .frame(width: 110, height: 110)

                    Image(systemName: "map.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(
                            LinearGradient(colors: [.cctv, .activeFlow],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .scaleEffect(iconScale)
                }
                .shadow(color: .cctv.opacity(iconGlow * 0.5), radius: 20)
                .onTapGesture { burst() }

                // Tap hint
                if !tapped {
                    Text("TAP")
                        .font(AppFont.caption(10))
                        .foregroundColor(.cctv.opacity(0.6))
                        .tracking(3)
                        .offset(y: 80)
                }
            }
            .frame(height: 260)
            .animation(.spring, value: tapped)

            Spacer().frame(height: 48)

            // Text
            VStack(spacing: 14) {
                Text("Organize your activity")
                    .font(AppFont.title(28))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Keep important actions in one place.\nYour routes, trips, and fuel — all tracked.")
                    .font(AppFont.body(15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .onAppear { pulseIcon() }
        .onDisappear { isVisible = false }
    }

    private func burst() {
        tapped = true
        // Generate particles
        let colors: [Color] = [.cctv, .warning, .freeRoad, .activeFlow, .congestion]
        particles = (0..<14).map { _ in
            let angle = Double.random(in: 0..<360) * .pi / 180
            let dist = CGFloat.random(in: 70...120)
            return (id: UUID(),
                    offset: CGSize(width: cos(angle) * dist, height: sin(angle) * dist),
                    color: colors.randomElement()!,
                    scale: CGFloat.random(in: 0.6...1.4))
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            iconScale = 1.3
            iconGlow = 1
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.15)) {
            iconScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.4)) { tapped = false }
            particles.removeAll()
        }
    }

    private func pulseIcon() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            iconGlow = 0.3
        }
    }
}

// MARK: - Page 2: Drag gesture
struct OnboardPage2: View {
    @Binding var isVisible: Bool
    let onNext: () -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var progress: Double = 0
    @State private var trailPoints: [CGPoint] = []
    @State private var carY: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Interactive drag scene
            ZStack {
                // Road background
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBg.opacity(0.6))
                    .frame(width: 260, height: 240)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.cctv.opacity(0.2), lineWidth: 1)
                    )

                // Road lines
                ForEach(0..<5, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.cctv.opacity(0.2))
                        .frame(width: 3, height: 24)
                        .offset(y: CGFloat(i * 40) - 80 + carY * 0.3)
                        .animation(.linear(duration: 0.1), value: carY)
                }

                // Trail
                Canvas { ctx, size in
                    guard trailPoints.count > 1 else { return }
                    var path = Path()
                    path.move(to: trailPoints[0])
                    for pt in trailPoints.dropFirst() { path.addLine(to: pt) }
                    ctx.stroke(path, with: .color(.cctv.opacity(0.4)), lineWidth: 2)
                }
                .frame(width: 260, height: 240)

                // Car icon (draggable)
                ZStack {
                    Circle()
                        .fill(Color.cctv.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .scaleEffect(isDragging ? 1.3 : 1.0)

                    Image(systemName: "car.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.cctv)
                }
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            isDragging = true
                            let clampedX = max(-100, min(100, val.translation.width))
                            let clampedY = max(-90, min(90, val.translation.height))
                            dragOffset = CGSize(width: clampedX, height: clampedY)
                            carY = val.translation.height
                            let center = CGPoint(x: 130 + clampedX, y: 120 + clampedY)
                            trailPoints.append(center)
                            if trailPoints.count > 30 { trailPoints.removeFirst() }
                            progress = min(1.0, progress + 0.05)
                        }
                        .onEnded { _ in
                            isDragging = false
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                dragOffset = .zero
                                carY = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                trailPoints.removeAll()
                            }
                        }
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)

                // Progress bar
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.cctv)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.textMuted.opacity(0.3)).frame(height: 4)
                                Capsule().fill(Color.cctv).frame(width: geo.size.width * progress, height: 4)
                                    .animation(.spring, value: progress)
                            }
                        }
                        .frame(height: 4)
                        Text("\(Int(progress * 100))%")
                            .font(AppFont.mono(10))
                            .foregroundColor(.cctv)
                            .frame(width: 32)
                    }
                    .padding(12)
                }
                .frame(width: 260, height: 240)

                // Drag hint
                if !isDragging && progress < 0.1 {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.draw.fill")
                            .font(.system(size: 12))
                        Text("DRAG CAR")
                            .font(AppFont.caption(10))
                            .tracking(2)
                    }
                    .foregroundColor(.cctv.opacity(0.5))
                    .offset(y: -110)
                }
            }
            .frame(height: 270)

            Spacer().frame(height: 48)

            VStack(spacing: 14) {
                Text("Track your progress")
                    .font(AppFont.title(28))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Use stats, history and reminders.\nEvery trip analyzed in real time.")
                    .font(AppFont.body(15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .onDisappear { isVisible = false }
    }
}

// MARK: - Page 3: Scroll-driven animation
struct OnboardPage3: View {
    @Binding var isVisible: Bool
    let onNext: () -> Void

    @State private var scrollOffset: CGFloat = 0
    @State private var barHeights: [CGFloat] = [0.3, 0.6, 0.45, 0.8, 0.55, 0.9, 0.7]
    @State private var appeared = false
    @State private var glowPhase: Double = 0
    @State private var selectedBar = 4

    let barColors: [Color] = [.cctv, .freeRoad, .warning, .cctv, .activeFlow, .freeRoad, .cctv]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Chart illustration with scroll interaction
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBg.opacity(0.7))
                    .frame(width: 280, height: 220)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.cctv.opacity(0.2), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TRAFFIC SCORE")
                                .font(AppFont.caption(10))
                                .foregroundColor(.textMuted)
                                .tracking(2)
                            Text("Weekly Overview")
                                .font(AppFont.headline(14))
                                .foregroundColor(.textPrimary)
                        }
                        Spacer()
                        ZStack {
                            Circle().fill(Color.freeRoad.opacity(0.2)).frame(width: 36, height: 36)
                            Text("\(Int(barHeights[selectedBar] * 100))")
                                .font(AppFont.mono(13))
                                .foregroundColor(.freeRoad)
                        }
                    }

                    // Bar chart
                    let days = ["M", "T", "W", "T", "F", "S", "S"]
                    HStack(alignment: .bottom, spacing: 10) {
                        ForEach(0..<7, id: \.self) { i in
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [barColors[i], barColors[i].opacity(0.4)],
                                            startPoint: .top, endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 24, height: appeared ? barHeights[i] * 100 : 4)
                                    .overlay(
                                        selectedBar == i ?
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1) : nil
                                    )
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.07), value: appeared)
                                    .onTapGesture { withAnimation(.spring) { selectedBar = i } }

                                Text(days[i])
                                    .font(AppFont.caption(10))
                                    .foregroundColor(selectedBar == i ? .cctv : .textMuted)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .frame(height: 230)
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onChanged { val in
                        let idx = Int((val.location.x / 280) * 7)
                        let clamped = max(0, min(6, idx))
                        withAnimation(.spring) { selectedBar = clamped }
                        // Animate the selected bar
                        withAnimation(.spring) {
                            barHeights[clamped] = min(1.0, barHeights[clamped] + 0.05)
                        }
                    }
            )

            Spacer().frame(height: 48)

            VStack(spacing: 14) {
                Text("Get useful insights")
                    .font(AppFont.title(28))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Make better decisions with simple data.\nSlide across the chart to explore.")
                    .font(AppFont.body(15))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { appeared = true }
            }
        }
        .onDisappear { isVisible = false; appeared = false }
    }
}
