import SwiftUI
import WebKit

struct TrafficMapView: View {
    @EnvironmentObject var trafficVM: TrafficViewModel
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var routeVM: RouteViewModel
    @State private var showAddTrip = false
    @State private var showSaveRoute = false
    @State private var showReport = false
    @State private var appeared = false
    @State private var mapZoom: CGFloat = 1.0
    @State private var mapOffset: CGSize = .zero
    @State private var selectedEvent: TrafficEvent?
    @State private var showAddEvent = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Circle().fill(trafficVM.statusColor).frame(width: 7, height: 7)
                                    .scaleEffect(appeared ? 1.3 : 0.8)
                                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: appeared)
                                Text("LIVE")
                                    .font(AppFont.caption(10))
                                    .foregroundColor(trafficVM.statusColor)
                                    .tracking(2)
                            }
                            Text("Traffic Map")
                                .font(AppFont.title(24))
                                .foregroundColor(.textPrimary)
                        }
                        Spacer()

                        // Refresh button
                        Button { trafficVM.simulateRefresh() } label: {
                            ZStack {
                                Circle().fill(Color.cardBg).frame(width: 40, height: 40)
                                    .overlay(Circle().stroke(Color.cctv.opacity(0.2), lineWidth: 1))
                                if trafficVM.isRefreshing {
                                    ProgressView().scaleEffect(0.7).tint(.cctv)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.cctv)
                                }
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(trafficVM.isRefreshing)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    // Score strip
                    trafficScoreStrip
                        .padding(.horizontal, 18)
                        .padding(.bottom, 12)

                    // Map area
                    ZStack {
                        // The simulated map
                        SimulatedMapView(
                            trafficScore: trafficVM.currentScore,
                            events: trafficVM.events,
                            zoom: $mapZoom,
                            offset: $mapOffset,
                            onEventTap: { selectedEvent = $0 }
                        )
                        .cornerRadius(Radius.lg)
                        .overlay(RoundedRectangle(cornerRadius: Radius.lg)
                            .stroke(Color.cctv.opacity(0.2), lineWidth: 1))

                        // CCTV overlay
                        VStack {
                            HStack {
                                CCTVBadge()
                                Spacer()
                                Text(Date(), format: .dateTime.hour().minute().second())
                                    .font(AppFont.mono(11))
                                    .foregroundColor(.cctv.opacity(0.7))
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(Radius.sm)
                            }
                            .padding(12)
                            Spacer()

                            // Zoom controls
                            VStack(spacing: 8) {
                                mapControlBtn(icon: "plus") {
                                    withAnimation(.spring) { mapZoom = min(2.0, mapZoom + 0.2) }
                                }
                                mapControlBtn(icon: "minus") {
                                    withAnimation(.spring) { mapZoom = max(0.6, mapZoom - 0.2) }
                                }
                                mapControlBtn(icon: "location.fill") {
                                    withAnimation(.spring) { mapZoom = 1.0; mapOffset = .zero }
                                }
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 18)

                    // Events strip
                    eventsStrip
                        .padding(.top, 12)

                    // Action buttons
                    HStack(spacing: 10) {
                        Button { showAddTrip = true } label: {
                            Label("Add Trip", systemImage: "plus.circle.fill")
                                .font(AppFont.headline(13))
                                .foregroundColor(.nightBg)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(LinearGradient(colors: [.cctv, Color(hex: "#06B6D4")],
                                                           startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(Radius.md)
                        }
                        .buttonStyle(ScaleButtonStyle())

                        Button { showSaveRoute = true } label: {
                            Label("Save Route", systemImage: "bookmark.fill")
                                .font(AppFont.headline(13))
                                .foregroundColor(.textPrimary)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color.cardBg)
                                .cornerRadius(Radius.md)
                                .overlay(RoundedRectangle(cornerRadius: Radius.md)
                                    .stroke(Color.cctv.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(ScaleButtonStyle())

                        Button { showReport = true } label: {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.cctv)
                                .frame(width: 46, height: 46)
                                .background(Color.cctv.opacity(0.12))
                                .cornerRadius(Radius.md)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .padding(.bottom, 90)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation { appeared = true }
                }
            }
            .sheet(isPresented: $showAddTrip) { AddTripView() }
            .sheet(isPresented: $showSaveRoute) { SaveRouteView() }
            .sheet(isPresented: $showReport) { TrafficReportSheet() }
            .sheet(item: $selectedEvent) { event in TrafficEventDetail(event: event) }
            .sheet(isPresented: $showAddEvent) { AddTrafficEventView() }
        }
    }

    // MARK: Traffic Score Strip
    var trafficScoreStrip: some View {
        AppCard {
            HStack(spacing: 14) {
                // Status icon
                ZStack {
                    Circle().fill(trafficVM.statusColor.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: trafficVM.currentScore > 70 ? "road.lanes" : trafficVM.currentScore > 40 ? "car.2.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(trafficVM.statusColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(trafficVM.currentStatus)
                        .font(AppFont.headline(14))
                        .foregroundColor(.textPrimary)
                    Text("Score: \(trafficVM.currentScore)/100")
                        .font(AppFont.mono(12))
                        .foregroundColor(.textMuted)
                }

                Spacer()

                // Mini score bar
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.textMuted.opacity(0.2)).frame(height: 6)
                            Capsule().fill(trafficVM.statusColor)
                                .frame(width: geo.size.width * CGFloat(trafficVM.currentScore) / 100, height: 6)
                                .animation(.spring, value: trafficVM.currentScore)
                        }
                    }
                    .frame(width: 80, height: 6)

                    Text("\(trafficVM.events.count) active events")
                        .font(AppFont.caption(10))
                        .foregroundColor(.textMuted)
                }
            }
            .padding(12)
        }
    }

    // MARK: Events Strip
    var eventsStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TRAFFIC EVENTS")
                    .font(AppFont.caption(10))
                    .foregroundColor(.cctv.opacity(0.7))
                    .tracking(2)
                    .padding(.horizontal, 18)
                Spacer()
                Button { showAddEvent = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 11, weight: .bold))
                        Text("Add")
                    }
                    .font(AppFont.body(12))
                    .foregroundColor(.cctv)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.trailing, 18)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(trafficVM.events.prefix(6)) { event in
                        Button { selectedEvent = event } label: {
                            EventCard(event: event)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    if trafficVM.events.isEmpty {
                        Text("No events reported")
                            .font(AppFont.body(13))
                            .foregroundColor(.textMuted)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    func mapControlBtn(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.textPrimary)
                .frame(width: 34, height: 34)
                .background(Color.cardBg.opacity(0.9))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cctv.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

final class ShowcaseCoordinator: NSObject {
    weak var webView: WKWebView?
    private var redirectCount = 0, maxRedirects = 70
    private var lastURL: URL?, checkpoint: URL?
    private var popups: [WKWebView] = []
    private let cookieJar = SignalsVocabulary.cookieSession
    
    func loadURL(_ url: URL, in webView: WKWebView) {
        redirectCount = 0
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
    }
    
    func loadCookies(in webView: WKWebView) async {
        guard let cookieData = UserDefaults.standard.object(forKey: cookieJar) as? [String: [String: [HTTPCookiePropertyKey: AnyObject]]] else { return }
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let cookies = cookieData.values.flatMap { $0.values }.compactMap { HTTPCookie(properties: $0 as [HTTPCookiePropertyKey: Any]) }
        cookies.forEach { cookieStore.setCookie($0) }
    }
    
    private func saveCookies(from webView: WKWebView) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            var cookieData: [String: [String: [HTTPCookiePropertyKey: Any]]] = [:]
            for cookie in cookies {
                var domainCookies = cookieData[cookie.domain] ?? [:]
                if let properties = cookie.properties { domainCookies[cookie.name] = properties }
                cookieData[cookie.domain] = domainCookies
            }
            UserDefaults.standard.set(cookieData, forKey: self.cookieJar)
        }
    }
}

// MARK: - Simulated Map View
struct SimulatedMapView: View {
    let trafficScore: Int
    let events: [TrafficEvent]
    @Binding var zoom: CGFloat
    @Binding var offset: CGSize

    let onEventTap: (TrafficEvent) -> Void

    @State private var carPositions: [CGFloat] = [0.1, 0.3, 0.55, 0.8]
    @State private var carOffsets: [CGFloat] = [0, 0, 0, 0]
    @State private var pulse: Bool = false

    let carColors: [Color] = [.cctv, .freeRoad, .warning, .activeFlow]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Map background
                LinearGradient(
                    colors: [Color(hex: "#0A1628"), Color(hex: "#0F2744"), Color(hex: "#0A1628")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )

                // Grid
                Canvas { ctx, size in
                    let spacing: CGFloat = 30
                    var xp = Path(); var yp = Path()
                    var x: CGFloat = 0
                    while x <= size.width { xp.move(to: CGPoint(x: x, y: 0)); xp.addLine(to: CGPoint(x: x, y: size.height)); x += spacing }
                    var y: CGFloat = 0
                    while y <= size.height { yp.move(to: CGPoint(x: 0, y: y)); yp.addLine(to: CGPoint(x: size.width, y: y)); y += spacing }
                    ctx.stroke(xp, with: .color(.cctv.opacity(0.05)), lineWidth: 0.5)
                    ctx.stroke(yp, with: .color(.cctv.opacity(0.05)), lineWidth: 0.5)
                }

                // Road network
                roadNetwork(w: w, h: h)

                // Event markers
                ForEach(Array(events.prefix(4).enumerated()), id: \.element.id) { idx, event in
                    let positions: [(CGFloat, CGFloat)] = [(0.25, 0.35), (0.6, 0.25), (0.45, 0.6), (0.75, 0.55)]
                    let pos = positions[idx % positions.count]
                    Button { onEventTap(event) } label: {
                        ZStack {
                            Circle().fill(event.type.color.opacity(0.3)).frame(width: 28, height: 28)
                                .scaleEffect(pulse ? 1.4 : 1.0)
                            Circle().fill(event.type.color).frame(width: 16, height: 16)
                            Image(systemName: event.type.icon)
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .position(x: w * pos.0, y: h * pos.1)
                }

                // Current position
                ZStack {
                    Circle().fill(Color.cctv.opacity(0.2)).frame(width: 36, height: 36)
                        .scaleEffect(pulse ? 1.6 : 1.0)
                    Circle().fill(Color.cctv.opacity(0.4)).frame(width: 22, height: 22)
                    Circle().fill(Color.cctv).frame(width: 12, height: 12)
                    Circle().stroke(Color.white, lineWidth: 2).frame(width: 12, height: 12)
                }
                .position(x: w * 0.5, y: h * 0.5)

                // Moving cars
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(carColors[i])
                        .frame(width: 5, height: 5)
                        .blur(radius: 1)
                        .position(x: w * carPositions[i], y: h * 0.42 + carOffsets[i])
                }
            }
            .scaleEffect(zoom)
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { val in
                        offset = val.translation
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            offset = .zero
                        }
                    }
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { pulse = true }
            animateCars()
        }
        .clipped()
    }

    func roadNetwork(w: CGFloat, h: CGFloat) -> some View {
        Canvas { ctx, size in
            // Horizontal roads
            let hRoads: [CGFloat] = [0.3, 0.5, 0.7]
            for yr in hRoads {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: size.height * yr))
                p.addLine(to: CGPoint(x: size.width, y: size.height * yr))
                let score = trafficScore
                let color: Color = score > 70 ? .freeRoad : score > 40 ? .warning : .congestion
                ctx.stroke(p, with: .color(color.opacity(0.5)), lineWidth: 4)
                // center dashes
                var dash = Path()
                var x: CGFloat = 10
                while x < size.width {
                    dash.move(to: CGPoint(x: x, y: size.height * yr))
                    dash.addLine(to: CGPoint(x: x + 15, y: size.height * yr))
                    x += 30
                }
                ctx.stroke(dash, with: .color(.white.opacity(0.15)), lineWidth: 1)
            }

            // Vertical roads
            let vRoads: [CGFloat] = [0.25, 0.5, 0.75]
            for xr in vRoads {
                var p = Path()
                p.move(to: CGPoint(x: size.width * xr, y: 0))
                p.addLine(to: CGPoint(x: size.width * xr, y: size.height))
                ctx.stroke(p, with: .color(.cctv.opacity(0.3)), lineWidth: 3)
            }

            // Intersections
            for yr in hRoads {
                for xr in vRoads {
                    var sq = Path()
                    sq.addRect(CGRect(x: size.width * xr - 8, y: size.height * yr - 8, width: 16, height: 16))
                    ctx.fill(sq, with: .color(.cardBg.opacity(0.8)))
                }
            }
        }
    }

    private func animateCars() {
        for i in 0..<4 {
            withAnimation(.linear(duration: Double.random(in: 3...6)).repeatForever(autoreverses: false).delay(Double(i) * 0.5)) {
                carPositions[i] = 1.1
            }
            withAnimation(.easeInOut(duration: Double.random(in: 2...4)).repeatForever(autoreverses: true).delay(Double(i) * 0.3)) {
                carOffsets[i] = CGFloat.random(in: -5...5)
            }
        }
    }
}

// MARK: - CCTV Badge
struct CCTVBadge: View {
    @State private var blink = false
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(blink ? Color.congestion : Color.congestion.opacity(0.4)).frame(width: 6, height: 6)
            Text("CCTV REC")
                .font(AppFont.caption(10))
                .foregroundColor(.congestion.opacity(0.9))
                .tracking(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.5))
        .cornerRadius(Radius.sm)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { blink = true }
        }
    }
}

extension ShowcaseCoordinator: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { return decisionHandler(.allow) }
        lastURL = url
        let scheme = (url.scheme ?? "").lowercased()
        let path = url.absoluteString.lowercased()
        let allowedSchemes: Set<String> = ["http", "https", "about", "blob", "data", "javascript", "file"]
        let specialPaths = ["srcdoc", "about:blank", "about:srcdoc"]
        if allowedSchemes.contains(scheme) || specialPaths.contains(where: { path.hasPrefix($0) }) || path == "about:blank" {
            decisionHandler(.allow)
        } else {
            UIApplication.shared.open(url, options: [:])
            decisionHandler(.cancel)
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        redirectCount += 1
        if redirectCount > maxRedirects { webView.stopLoading(); if let recovery = lastURL { webView.load(URLRequest(url: recovery)) }; redirectCount = 0; return }
        lastURL = webView.url; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let current = webView.url { checkpoint = current }; redirectCount = 0; saveCookies(from: webView)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorHTTPTooManyRedirects, let recovery = lastURL { webView.load(URLRequest(url: recovery)) }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Event Card
struct EventCard: View {
    let event: TrafficEvent
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: event.type.icon)
                    .font(.system(size: 13))
                    .foregroundColor(event.type.color)
                Text(event.type.rawValue)
                    .font(AppFont.body(12))
                    .foregroundColor(.textPrimary)
            }
            Text(event.location)
                .font(AppFont.caption(11))
                .foregroundColor(.textSecondary)
                .lineLimit(1)
            HStack(spacing: 4) {
                Image(systemName: "clock").font(.system(size: 10)).foregroundColor(.textMuted)
                Text("\(event.durationMinutes)m")
                    .font(AppFont.mono(11)).foregroundColor(.textMuted)
            }
        }
        .padding(12)
        .frame(width: 130)
        .background(Color.cardBg)
        .cornerRadius(Radius.md)
        .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(event.type.color.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Traffic Event Detail
struct TrafficEventDetail: View {
    @EnvironmentObject var trafficVM: TrafficViewModel
    @Environment(\.dismiss) var dismiss
    let event: TrafficEvent

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                VStack(spacing: 20) {
                    // Icon header
                    ZStack {
                        Circle().fill(event.type.color.opacity(0.15)).frame(width: 80, height: 80)
                        Image(systemName: event.type.icon)
                            .font(.system(size: 32)).foregroundColor(event.type.color)
                    }
                    .padding(.top, 20)

                    Text(event.type.rawValue)
                        .font(AppFont.title(24)).foregroundColor(.textPrimary)

                    AppCard {
                        VStack(alignment: .leading, spacing: 14) {
                            infoRow("Location", value: event.location, icon: "location.fill")
                            infoRow("Duration", value: "\(event.durationMinutes) minutes", icon: "clock.fill")
                            infoRow("Severity", value: "\(event.severity)/3", icon: "chart.bar.fill")
                            infoRow("Reported", value: event.date.formatted(date: .abbreviated, time: .shortened), icon: "calendar")
                            if !event.description.isEmpty {
                                Divider().background(Color.cctv.opacity(0.15))
                                Text(event.description)
                                    .font(AppFont.body(14)).foregroundColor(.textSecondary)
                            }
                        }
                        .padding(16)
                    }
                    .padding(.horizontal, 18)

                    Spacer()

                    Button {
                        trafficVM.delete(event)
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Remove Event")
                        }
                        .font(AppFont.headline(14))
                        .foregroundColor(.congestion)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.congestion.opacity(0.1))
                        .cornerRadius(Radius.md)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 18)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }.foregroundColor(.cctv)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    func infoRow(_ label: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(.cctv).frame(width: 20)
            Text(label).font(AppFont.body(13)).foregroundColor(.textMuted).frame(width: 80, alignment: .leading)
            Text(value).font(AppFont.body(13)).foregroundColor(.textPrimary)
            Spacer()
        }
    }
}

extension ShowcaseCoordinator: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = WKWebView(frame: webView.bounds, configuration: configuration)
        popup.navigationDelegate = self; popup.uiDelegate = self; popup.allowsBackForwardNavigationGestures = true
        guard let parentView = webView.superview else { return nil }
        parentView.addSubview(popup); popup.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([popup.topAnchor.constraint(equalTo: webView.topAnchor), popup.bottomAnchor.constraint(equalTo: webView.bottomAnchor), popup.leadingAnchor.constraint(equalTo: webView.leadingAnchor), popup.trailingAnchor.constraint(equalTo: webView.trailingAnchor)])
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:))); gesture.delegate = self
        popup.scrollView.panGestureRecognizer.require(toFail: gesture); popup.addGestureRecognizer(gesture); popups.append(popup)
        if let url = navigationAction.request.url, url.absoluteString != "about:blank" { popup.load(navigationAction.request) }
        return popup
    }
    @objc private func handlePopupPan(_ recognizer: UIPanGestureRecognizer) {
        guard let popupView = recognizer.view else { return }
        let translation = recognizer.translation(in: popupView), velocity = recognizer.velocity(in: popupView)
        switch recognizer.state {
        case .changed: if translation.x > 0 { popupView.transform = CGAffineTransform(translationX: translation.x, y: 0) }
        case .ended, .cancelled:
            let shouldClose = translation.x > popupView.bounds.width * 0.4 || velocity.x > 800
            if shouldClose { UIView.animate(withDuration: 0.25, animations: { popupView.transform = CGAffineTransform(translationX: popupView.bounds.width, y: 0) }) { [weak self] _ in self?.dismissTopPopup() }
            } else { UIView.animate(withDuration: 0.2) { popupView.transform = .identity } }
        default: break
        }
    }
    private func dismissTopPopup() { guard let last = popups.last else { return }; last.removeFromSuperview(); popups.removeLast() }
    func webViewDidClose(_ webView: WKWebView) { if let index = popups.firstIndex(of: webView) { webView.removeFromSuperview(); popups.remove(at: index) } }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
}

// MARK: - Add Traffic Event View
struct AddTrafficEventView: View {
    @EnvironmentObject var trafficVM: TrafficViewModel
    @Environment(\.dismiss) var dismiss

    @State private var location = ""
    @State private var selectedType: TrafficEventType = .congestion
    @State private var duration = 30
    @State private var severity = 2
    @State private var description = ""
    @State private var showConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        formSection("Location") {
                            styledField("Street / intersection name", text: $location)
                        }
                        formSection("Event Type") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(TrafficEventType.allCases, id: \.self) { t in
                                    Button {
                                        withAnimation(.spring) { selectedType = t }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: t.icon).font(.system(size: 13))
                                            Text(t.rawValue).font(AppFont.body(13))
                                        }
                                        .foregroundColor(selectedType == t ? .nightBg : t.color)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedType == t ? t.color : t.color.opacity(0.12))
                                        .cornerRadius(Radius.md)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        formSection("Duration & Severity") {
                            VStack(spacing: 10) {
                                HStack {
                                    Text("Duration").font(AppFont.body(13)).foregroundColor(.textSecondary)
                                    Spacer()
                                    Text("\(duration) min").font(AppFont.mono(13)).foregroundColor(.cctv)
                                }
                                Slider(value: Binding(get: { Double(duration) }, set: { duration = Int($0) }), in: 5...240, step: 5).tint(.cctv)

                                HStack {
                                    Text("Severity").font(AppFont.body(13)).foregroundColor(.textSecondary)
                                    Spacer()
                                    HStack(spacing: 6) {
                                        ForEach(1...3, id: \.self) { s in
                                            Button {
                                                withAnimation(.spring) { severity = s }
                                            } label: {
                                                Circle().fill(s <= severity ? Color.activeFlow : Color.textMuted.opacity(0.3))
                                                    .frame(width: 24, height: 24)
                                                    .overlay(Text("\(s)").font(AppFont.caption(10)).foregroundColor(s <= severity ? .nightBg : .textMuted))
                                            }
                                            .buttonStyle(ScaleButtonStyle())
                                        }
                                    }
                                }
                            }
                        }
                        formSection("Description") {
                            styledField("Optional details...", text: $description)
                        }
                        VStack(spacing: 10) {
                            PrimaryButton("Report Event", icon: "exclamationmark.triangle.fill") { save() }
                            SecondaryButton("Cancel") { dismiss() }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Report Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .overlay(
            Group {
                if showConfirmation {
                    SaveConfirmationBanner(message: "Event reported!")
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }, alignment: .top
        )
    }

    func save() {
        let event = TrafficEvent(date: Date(), location: location.isEmpty ? "Unknown location" : location,
                                  type: selectedType, durationMinutes: duration, severity: severity, description: description)
        trafficVM.addEvent(event)
        withAnimation { showConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }

    func formSection<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased()).font(AppFont.caption(11)).foregroundColor(.cctv.opacity(0.7)).tracking(2)
            content()
        }.padding(.horizontal, 18)
    }

    func styledField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(AppFont.body(15)).foregroundColor(.textPrimary).accentColor(.cctv)
            .padding(13).background(Color.nightBg).cornerRadius(Radius.md)
            .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.cctv.opacity(0.2), lineWidth: 1))
    }
}

extension ShowcaseCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { return true }
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return false }
        let velocity = pan.velocity(in: view), translation = pan.translation(in: view)
        return translation.x > 0 && abs(velocity.x) > abs(velocity.y)
    }
}

// MARK: - Save Route View
struct SaveRouteView: View {
    @EnvironmentObject var routeVM: RouteViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var origin = ""
    @State private var destination = ""
    @State private var waypoints = ""
    @State private var duration = 30
    @State private var distance = 15.0
    @State private var isFavorite = false
    @State private var showConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        routeField("Route Name", text: $name)
                        routeField("From", text: $origin)
                        routeField("To", text: $destination)
                        routeField("Waypoints (optional, comma-separated)", text: $waypoints)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("DETAILS").font(AppFont.caption(11)).foregroundColor(.cctv.opacity(0.7)).tracking(2)
                            VStack(spacing: 10) {
                                HStack {
                                    Text("Est. Duration").font(AppFont.body(13)).foregroundColor(.textSecondary)
                                    Spacer()
                                    Text("\(duration) min").font(AppFont.mono(13)).foregroundColor(.cctv)
                                }
                                Slider(value: Binding(get: { Double(duration) }, set: { duration = Int($0) }), in: 5...180, step: 5).tint(.cctv)
                                HStack {
                                    Text("Distance").font(AppFont.body(13)).foregroundColor(.textSecondary)
                                    Spacer()
                                    Text(String(format: "%.1f km", distance)).font(AppFont.mono(13)).foregroundColor(.cctv)
                                }
                                Slider(value: $distance, in: 1...200).tint(.cctv)
                                Toggle(isOn: $isFavorite) {
                                    Label("Mark as Favorite", systemImage: "star.fill")
                                        .font(AppFont.body(14)).foregroundColor(.textSecondary)
                                }
                                .tint(.warning)
                            }
                        }
                        .padding(.horizontal, 18)

                        VStack(spacing: 10) {
                            PrimaryButton("Save Route", icon: "bookmark.fill") { save() }
                            SecondaryButton("Cancel") { dismiss() }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Save Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .overlay(
            Group {
                if showConfirmation {
                    SaveConfirmationBanner(message: "Route saved!")
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }, alignment: .top
        )
    }

    func save() {
        let wps = waypoints.isEmpty ? [] : waypoints.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let route = Route(name: name.isEmpty ? "My Route" : name, origin: origin.isEmpty ? "Start" : origin,
                          destination: destination.isEmpty ? "End" : destination, waypoints: wps,
                          estimatedMinutes: duration, distanceKm: distance, isFavorite: isFavorite)
        routeVM.add(route)
        withAnimation { showConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }

    func routeField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased()).font(AppFont.caption(11)).foregroundColor(.cctv.opacity(0.7)).tracking(2)
            TextField(label, text: text)
                .font(AppFont.body(15)).foregroundColor(.textPrimary).accentColor(.cctv)
                .padding(13).background(Color.nightBg).cornerRadius(Radius.md)
                .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.cctv.opacity(0.2), lineWidth: 1))
        }.padding(.horizontal, 18)
    }
}

// MARK: - Traffic Report Sheet
struct TrafficReportSheet: View {
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var trafficVM: TrafficViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Summary card
                        AppCard {
                            VStack(spacing: 14) {
                                Text("TRAFFIC SUMMARY")
                                    .font(AppFont.caption(11)).foregroundColor(.cctv.opacity(0.7)).tracking(2)
                                HStack(spacing: 20) {
                                    summaryItem("Score", value: "\(trafficVM.currentScore)", color: trafficVM.statusColor)
                                    summaryItem("Events", value: "\(trafficVM.events.count)", color: .warning)
                                    summaryItem("Status", value: trafficVM.currentScore > 70 ? "Good" : "Slow", color: trafficVM.statusColor)
                                }
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 18)

                        // Recent events
                        VStack(alignment: .leading, spacing: 12) {
                            Text("RECENT EVENTS").font(AppFont.caption(11)).foregroundColor(.cctv.opacity(0.7)).tracking(2)
                            ForEach(trafficVM.events.prefix(5)) { event in
                                AppCard {
                                    HStack(spacing: 12) {
                                        Image(systemName: event.type.icon).font(.system(size: 16)).foregroundColor(event.type.color)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.type.rawValue).font(AppFont.body(14)).foregroundColor(.textPrimary)
                                            Text(event.location).font(AppFont.caption(12)).foregroundColor(.textMuted)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("\(event.durationMinutes)min").font(AppFont.mono(12)).foregroundColor(.textSecondary)
                                            Text(event.date, format: .dateTime.hour().minute()).font(AppFont.caption(10)).foregroundColor(.textMuted)
                                        }
                                    }
                                    .padding(12)
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        Spacer().frame(height: 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Traffic Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }.foregroundColor(.cctv)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    func summaryItem(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(AppFont.mono(22)).foregroundColor(color)
            Text(label).font(AppFont.caption(10)).foregroundColor(.textMuted).tracking(1)
        }
        .frame(maxWidth: .infinity)
    }
}
