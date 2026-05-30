import SwiftUI
import Combine
import Network

struct SplashView: View {

    // Phase 1: Background
    @State private var bgOpacity: Double = 0
    @State private var bgScale: CGFloat = 1.1
    @State private var networkMonitor = NWPathMonitor()

    // Phase 2: Road lines & scan elements
    @State private var roadLineOffset: CGFloat = -300
    @State private var scanAlpha: Double = 0
    @State private var dotAlpha: [Double] = [0, 0, 0, 0, 0, 0]
    @State private var dotScale: [CGFloat] = [0.3, 0.3, 0.3, 0.3, 0.3, 0.3]
    @State private var radarRotation: Double = 0
    @State private var radarRingScale: CGFloat = 0
    
    @StateObject private var steerer = TrafficPulseSteerer()

    // Phase 3: Logo
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var taglineY: CGFloat = 20

    // Phase 4: Exit
    @State private var exitScale: CGFloat = 1.0
    @State private var exitOpacity: Double = 1.0

    // Loop animations
    @State private var isVisible = true
    @State private var scanSweep: Double = 0
    @State private var pulseMult: CGFloat = 1.0
    @State private var carPositions: [CGFloat] = [-1, -0.6, -0.2, 0.4]
    @State private var carAlpha: [Double] = [0, 0, 0, 0]
    @State private var cancellables = Set<AnyCancellable>()

    let carColors: [Color] = [.cctv, .warning, .activeFlow, .freeRoad]

    var body: some View {
        NavigationView {
            ZStack {
                // LAYER 1 — Background
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#080E1C"), Color(hex: "#0F172A"), Color(hex: "#0A1628")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .ignoresSafeArea()
                    .opacity(bgOpacity)
                    .scaleEffect(bgScale)
                
                NavigationLink(
                    destination: TrafficPulseShowcase().navigationBarHidden(true),
                    isActive: $steerer.navigateToWeb
                ) { EmptyView() }
                
                NavigationLink(
                    destination: MainView().navigationBarBackButtonHidden(true),
                    isActive: $steerer.navigateToMain
                ) { EmptyView() }

                // Grid
                GridPattern()
                    .ignoresSafeArea()
                    .opacity(bgOpacity * 0.8)

                // LAYER 2 — Road infrastructure
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height

                    // Horizontal road lines (CCTV white dashes)
                    ForEach(0..<6, id: \.self) { i in
                        let y = h * 0.3 + CGFloat(i) * 28
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.cctv.opacity(0.18))
                            .frame(width: 60, height: 3)
                            .offset(x: roadLineOffset + CGFloat(i * 80), y: y)
                            .opacity(scanAlpha)
                    }

                    // Moving cars along road
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(carColors[i])
                            .frame(width: 5, height: 5)
                            .blur(radius: 1)
                            .offset(x: w * carPositions[i], y: h * 0.3 + CGFloat(i) * 28)
                            .opacity(carAlpha[i])
                    }

                    // Vertical road stripe
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, Color.cctv.opacity(0.25), .clear],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: h * 0.4)
                        .offset(x: w * 0.5, y: h * 0.25)
                        .opacity(scanAlpha)

                    // CCTV Corner indicators
                    ForEach([CGPoint(x: 18, y: 18), CGPoint(x: w - 18, y: 18),
                              CGPoint(x: 18, y: h - 18), CGPoint(x: w - 18, y: h - 18)], id: \.x) { pt in
                        CCTVCorner()
                            .offset(x: pt.x - 10, y: pt.y - 10)
                            .opacity(scanAlpha * 0.7)
                    }

                    // Radar / tracking circle
                    ZStack {
                        ForEach(0..<3, id: \.self) { r in
                            Circle()
                                .stroke(Color.cctv.opacity(0.12 - Double(r) * 0.03), lineWidth: 1)
                                .frame(width: CGFloat(60 + r * 50), height: CGFloat(60 + r * 50))
                        }
                        // Sweep
                        Circle()
                            .trim(from: 0, to: 0.25)
                            .stroke(
                                AngularGradient(colors: [.clear, .cctv.opacity(0.5)],
                                                center: .center),
                                lineWidth: 2
                            )
                            .frame(width: 110, height: 110)
                            .rotationEffect(.degrees(radarRotation))

                        Circle()
                            .fill(Color.cctv)
                            .frame(width: 5, height: 5)
                    }
                    .scaleEffect(radarRingScale)
                    .position(x: w * 0.5, y: h * 0.38)

                    // Scan line
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [.clear, .cctv.opacity(0.15), .clear],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .frame(height: 80)
                        .offset(y: scanSweep)
                        .opacity(scanAlpha)
                        .clipped()
                }
                .clipped()

                // LAYER 3 — Logo & Title
                VStack(spacing: 0) {
                    Spacer()

                    // App Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#1E3A5F"), Color(hex: "#0F2744")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 88, height: 88)
                            .shadow(color: .cctv.opacity(0.4), radius: 20, x: 0, y: 8)

                        RoundedRectangle(cornerRadius: 28)
                            .stroke(
                                LinearGradient(colors: [.cctv.opacity(0.6), .cctv.opacity(0.1)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1.5
                            )
                            .frame(width: 88, height: 88)

                        Image(systemName: "road.lanes")
                            .font(.system(size: 36, weight: .light))
                            .foregroundStyle(
                                LinearGradient(colors: [.cctv, Color(hex: "#06B6D4")],
                                               startPoint: .top, endPoint: .bottom)
                            )
                            .scaleEffect(pulseMult)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    Spacer().frame(height: 24)

                    // App name
                    Text("Traffic Pulse")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.textPrimary, .textSecondary],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .opacity(titleOpacity)

                    Spacer().frame(height: 8)

                    // Tagline
                    Text("App loading...")
                        .font(AppFont.caption(14))
                        .foregroundColor(.cctv.opacity(0.8))
                        .tracking(3)
                        .offset(y: taglineY)
                        .opacity(subtitleOpacity)

                    Spacer()

                    // Status indicator (CCTV style)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.freeRoad)
                            .frame(width: 6, height: 6)
                            .scaleEffect(pulseMult)
                        Text("LIVE • MONITORING ACTIVE")
                            .font(AppFont.caption(10))
                            .foregroundColor(.textMuted)
                            .tracking(2)
                    }
                    .opacity(subtitleOpacity)
                    .padding(.bottom, 40)
                }
            }
            .opacity(exitOpacity)
            .scaleEffect(exitScale)
            .onAppear { startAnimation() }
            .fullScreenCover(isPresented: $steerer.showPermissionPrompt) {
                ConsentVista(steerer: steerer)
            }
            .onDisappear { isVisible = false; stopAnimations() }
            .fullScreenCover(isPresented: $steerer.showOfflineView) {
                OfflineScreen()
            }
        }
    }

    private func startAnimation() {
        // Phase 1: Background (0–0.6s)
        withAnimation(.easeIn(duration: 0.6)) {
            bgOpacity = 1
            bgScale = 1.0
        }

        // Phase 2: Road elements (0.6–1.4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard isVisible else { return }
            withAnimation(.easeOut(duration: 0.6)) {
                scanAlpha = 1
                radarRingScale = 1
                roadLineOffset = -200
            }
            startLoopAnimations()
        }
        
        setupStreams()
        setupNetworkMonitoring()
        steerer.ignite()

        // Phase 3: Logo entrance (1.4–2.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                logoScale = 1.0
                logoOpacity = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            guard isVisible else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                titleOpacity = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.7) {
            guard isVisible else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                subtitleOpacity = 1
                taglineY = 0
            }
        }
        
        func setupNetworkMonitoring() {
            networkMonitor.pathUpdateHandler = { path in
                Task { @MainActor in
                    steerer.networkConnectivityChanged(path.status == .satisfied)
                }
            }
            networkMonitor.start(queue: .global(qos: .background))
        }
        
    }

    private func startLoopAnimations() {
        guard isVisible else { return }

        // Radar rotation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            radarRotation = 360
        }

        // Pulse icon
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseMult = 1.08
        }

        // Scan sweep
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            scanSweep = UIScreen.main.bounds.height
        }

        // Animate cars
        for i in 0..<4 {
            let delay = Double(i) * 0.3
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard isVisible else { return }
                withAnimation(.easeIn(duration: 0.3)) { carAlpha[i] = 0.8 }
                withAnimation(.linear(duration: 2.5 + Double(i) * 0.4).repeatForever(autoreverses: false)) {
                    carPositions[i] = 1.2
                }
            }
        }
    }
    
    func setupStreams() {
        NotificationCenter.default.publisher(for: .attributionLanded)
            .compactMap { $0.userInfo?["conversionData"] as? [String: Any] }
            .sink { data in
                steerer.ingestAttribution(data)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .deeplinksLanded)
            .compactMap { $0.userInfo?["deeplinksData"] as? [String: Any] }
            .sink { data in
                steerer.ingestDeeplinks(data)
            }
            .store(in: &cancellables)
    }

    private func stopAnimations() {
        bgOpacity = 0; bgScale = 1.1
        scanAlpha = 0; radarRingScale = 0; radarRotation = 0
        logoScale = 0.4; logoOpacity = 0; titleOpacity = 0; subtitleOpacity = 0
        exitScale = 1.0; exitOpacity = 1.0; pulseMult = 1.0
        scanSweep = 0
        carPositions = [-1, -0.6, -0.2, 0.4]
        carAlpha = [0, 0, 0, 0]
    }
}

// MARK: - CCTV Corner Marker
struct CCTVCorner: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.cctv.opacity(0.7))
                .frame(width: 16, height: 2)
                .offset(x: 7, y: 0)
            Rectangle()
                .fill(Color.cctv.opacity(0.7))
                .frame(width: 2, height: 16)
                .offset(x: 0, y: 7)
        }
    }
}
