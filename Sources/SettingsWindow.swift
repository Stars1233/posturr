import AppKit
import SwiftUI
import ServiceManagement

// MARK: - Brand Colors

extension Color {
    static let brandCyan = Color(red: 0.31, green: 0.82, blue: 0.77)      // #4fd1c5
    static let brandNavy = Color(red: 0.10, green: 0.15, blue: 0.27)      // #1a2744
    static let sectionBackground = Color(NSColor.controlBackgroundColor).opacity(0.5)
}

// MARK: - Settings Window Controller

class SettingsWindowController: NSObject, NSWindowDelegate {
    var window: NSWindow?
    weak var appDelegate: AppDelegate?

    func showSettings(appDelegate: AppDelegate, fromStatusItem statusItem: NSStatusItem?) {
        self.appDelegate = appDelegate

        // Find the screen where the status item is located
        let targetScreen = statusItem?.button?.window?.screen ?? NSScreen.main ?? NSScreen.screens.first

        if let existingWindow = window {
            // Move existing window to the correct screen and center it
            if let screen = targetScreen {
                centerWindow(existingWindow, on: screen)
            }
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(appDelegate: appDelegate)
        let hostingController = NSHostingController(rootView: settingsView)

        // Calculate actual content size from SwiftUI view
        let fittingSize = hostingController.sizeThatFits(in: CGSize(width: 480, height: CGFloat.greatestFiniteMagnitude))

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: fittingSize.width, height: fittingSize.height),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.titlebarAppearsTransparent = false
        window.backgroundColor = NSColor.windowBackgroundColor

        // Center on the target screen
        if let screen = targetScreen {
            centerWindow(window, on: screen)
        } else {
            window.center()
        }

        self.window = window
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        // Only hide from Dock if user hasn't enabled "Show in Dock"
        if let appDelegate = appDelegate, !appDelegate.showInDock {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func centerWindow(_ window: NSWindow, on screen: NSScreen) {
        let screenFrame = screen.frame
        let windowSize = window.frame.size
        let x = screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - windowSize.height) / 2
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func close() {
        window?.close()
    }
}

// MARK: - Compact Slider

struct CompactSlider: View {
    let title: String
    let helpText: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let valueLabel: String

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 11))
                    .frame(width: 62, alignment: .leading)
                HelpButton(text: helpText)
            }

            Slider(value: $value, in: range, step: step)
                .tint(.brandCyan)
                .frame(maxWidth: .infinity)

            Text(valueLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.brandCyan)
                .frame(width: 70, alignment: .trailing)
        }
        .frame(height: 22)
    }
}

// MARK: - Compact Toggle

struct CompactToggle: View {
    let title: String
    let helpText: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 6) {
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(.brandCyan)
                .labelsHidden()
                .scaleEffect(0.65)
                .frame(width: 32)

            Text(title)
                .font(.system(size: 11))
                .lineLimit(1)

            HelpButton(text: helpText)

            Spacer(minLength: 0)
        }
        .frame(height: 22)
        .contentShape(Rectangle())
        .onTapGesture { isOn.toggle() }
    }
}

// MARK: - Compact Warning Style Picker

struct CompactWarningStylePicker: View {
    @Binding var selection: WarningMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach([WarningMode.blur, .vignette, .border, .solid, .none], id: \.self) { mode in
                Button(action: { selection = mode }) {
                    Text(mode.shortName)
                        .font(.system(size: 10, weight: selection == mode ? .semibold : .regular))
                        .foregroundColor(selection == mode ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(selection == mode ? Color.brandCyan : Color.clear)
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
    }
}

// MARK: - Compact Tracking Source Picker

struct CompactTrackingSourcePicker: View {
    @Binding var selection: TrackingSource
    let airPodsAvailable: Bool

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TrackingSource.allCases) { source in
                let isDisabled = source == .airpods && !airPodsAvailable
                Button(action: {
                    if !isDisabled { selection = source }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: source.icon)
                            .font(.system(size: 9))
                        Text(source.displayName)
                            .font(.system(size: 10, weight: selection == source ? .semibold : .regular))
                    }
                    .foregroundColor(selection == source ? .white : (isDisabled ? .secondary.opacity(0.5) : .primary))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(selection == source ? Color.brandCyan : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isDisabled)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
    }
}

// MARK: - Subtle Divider

struct SubtleDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.08))
            .frame(height: 1)
    }
}

extension WarningMode {
    var displayName: String {
        switch self {
        case .blur: return "Blur"
        case .vignette: return "Vignette"
        case .border: return "Border"
        case .solid: return "Solid"
        case .none: return "None"
        }
    }

    var shortName: String {
        switch self {
        case .blur: return "Blur"
        case .vignette: return "Vignette"
        case .border: return "Border"
        case .solid: return "Solid"
        case .none: return "None"
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    let appDelegate: AppDelegate

    // Local state that syncs with AppDelegate - initialized from appDelegate in init()
    @State private var intensity: Double
    @State private var deadZone: Double
    @State private var intensitySlider: Double
    @State private var deadZoneSlider: Double
    @State private var blurWhenAway: Bool
    @State private var showInDock: Bool
    @State private var pauseOnTheGo: Bool
    @State private var useCompatibilityMode: Bool
    @State private var selectedCameraID: String
    @State private var availableCameras: [(id: String, name: String)]
    @State private var warningMode: WarningMode
    @State private var warningColor: Color
    @State private var warningOnsetDelay: Double
    @State private var launchAtLogin: Bool
    @State private var toggleShortcutEnabled: Bool
    @State private var toggleShortcut: KeyboardShortcut
    @State private var detectionModeSlider: Double
    @State private var trackingSource: TrackingSource
    @State private var airPodsAvailable: Bool

    let detectionModes: [DetectionMode] = [.responsive, .balanced, .performance]

    let intensityValues: [Double] = [0.08, 0.15, 0.35, 0.65, 1.2]
    let intensityLabels = ["Gentle", "Easy", "Medium", "Firm", "Aggressive"]

    let deadZoneValues: [Double] = [0.0, 0.08, 0.15, 0.25, 0.40]
    let deadZoneLabels = ["Strict", "Tight", "Medium", "Relaxed", "Loose"]

    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate

        // Initialize all state from appDelegate synchronously to ensure correct sizing
        let cameras = appDelegate.cameraDetector.getAvailableCameras()
        let cameraList = cameras.map { (id: $0.uniqueID, name: $0.localizedName) }

        _intensity = State(initialValue: appDelegate.intensity)
        _deadZone = State(initialValue: appDelegate.deadZone)
        _intensitySlider = State(initialValue: Double(intensityValues.firstIndex(of: appDelegate.intensity) ?? 2))
        _deadZoneSlider = State(initialValue: Double(deadZoneValues.firstIndex(of: appDelegate.deadZone) ?? 2))
        _blurWhenAway = State(initialValue: appDelegate.blurWhenAway)
        _showInDock = State(initialValue: appDelegate.showInDock)
        _pauseOnTheGo = State(initialValue: appDelegate.pauseOnTheGo)
        _useCompatibilityMode = State(initialValue: appDelegate.useCompatibilityMode)
        _selectedCameraID = State(initialValue: appDelegate.selectedCameraID ?? cameras.first?.uniqueID ?? "")
        _availableCameras = State(initialValue: cameraList)
        _warningMode = State(initialValue: appDelegate.warningMode)
        _warningColor = State(initialValue: Color(appDelegate.warningColor))
        _warningOnsetDelay = State(initialValue: appDelegate.warningOnsetDelay)
        _launchAtLogin = State(initialValue: SMAppService.mainApp.status == .enabled)
        _toggleShortcutEnabled = State(initialValue: appDelegate.toggleShortcutEnabled)
        _toggleShortcut = State(initialValue: appDelegate.toggleShortcut)
        _detectionModeSlider = State(initialValue: Double(detectionModes.firstIndex(of: appDelegate.detectionMode) ?? 0))
        _trackingSource = State(initialValue: appDelegate.trackingSource)
        _airPodsAvailable = State(initialValue: appDelegate.airPodsDetector.isAvailable)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Compact Header
            HStack(spacing: 8) {
                if let appIcon = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 28, height: 28)
                }
                Text("Posturr")
                    .font(.system(size: 15, weight: .semibold))

                Spacer()

                // Social links
                HStack(spacing: 4) {
                    Link(destination: URL(string: "https://github.com/tldev/posturr")!) {
                        GitHubIcon(color: Color.secondary.opacity(0.6))
                            .frame(width: 14, height: 14)
                            .padding(3)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                    .help("View on GitHub")

                    Link(destination: URL(string: "https://discord.gg/6Ufy2SnXDW")!) {
                        DiscordIcon(color: Color.secondary.opacity(0.6))
                            .frame(width: 14, height: 14)
                            .padding(3)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                    .help("Join Discord")
                }

                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("v\(version)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.primary.opacity(0.05)))
                }
            }
            .padding(.bottom, 10)

            SubtleDivider()

            // Tracking & Warning Section
            VStack(spacing: 6) {
                // Tracking row
                HStack(spacing: 8) {
                    Text("Tracking")
                        .font(.system(size: 11, weight: .medium))
                        .frame(width: 58, alignment: .leading)

                    CompactTrackingSourcePicker(
                        selection: $trackingSource,
                        airPodsAvailable: airPodsAvailable
                    )
                    .frame(width: 130)
                    .onChange(of: trackingSource) { newValue in
                        if newValue != appDelegate.trackingSource {
                            appDelegate.switchTrackingSource(to: newValue)
                        }
                    }

                    if trackingSource == .camera {
                        if availableCameras.isEmpty {
                            Text("No cameras")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        } else {
                            Picker("", selection: $selectedCameraID) {
                                ForEach(availableCameras, id: \.id) { camera in
                                    Text(camera.name).tag(camera.id)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .onChange(of: selectedCameraID) { newValue in
                                if newValue != appDelegate.selectedCameraID {
                                    appDelegate.selectedCameraID = newValue
                                    appDelegate.saveSettings()
                                    appDelegate.restartCamera()
                                }
                            }
                        }
                    } else {
                        // AirPods status
                        HStack(spacing: 4) {
                            Image(systemName: airPodsAvailable ? "checkmark.circle.fill" : "exclamationmark.circle")
                                .foregroundColor(airPodsAvailable ? .green : .secondary)
                                .font(.system(size: 10))
                            Text(airPodsAvailable ? "Connected" : "Not connected")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }

                    // Recalibrate button
                    Button(action: { appDelegate.startCalibration() }) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 9, weight: .medium))
                            Text("Recalibrate")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.brandCyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(Color.brandCyan.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .frame(height: 26)

                // Warning row
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Text("Warning")
                            .font(.system(size: 11, weight: .medium))
                        HelpButton(text: "Blur obscures the screen, Vignette shows edge glow, Border shows colored borders, Solid fills screen. None disables visual warnings.")
                    }
                    .frame(width: 72, alignment: .leading)

                    CompactWarningStylePicker(selection: $warningMode)
                        .frame(maxWidth: .infinity)
                        .onChange(of: warningMode) { newValue in
                            if newValue != appDelegate.warningMode {
                                appDelegate.switchWarningMode(to: newValue)
                                appDelegate.saveSettings()
                            }
                        }

                    ColorPicker("", selection: $warningColor, supportsOpacity: false)
                        .labelsHidden()
                        .scaleEffect(0.8)
                        .frame(width: 28, height: 22)
                        .onChange(of: warningColor) { newValue in
                            let nsColor = NSColor(newValue)
                            appDelegate.updateWarningColor(nsColor)
                            appDelegate.saveSettings()
                        }
                }
                .frame(height: 26)
            }
            .padding(.vertical, 10)

            SubtleDivider()

            // Sensitivity Section
            VStack(spacing: 4) {
                CompactSlider(
                    title: "Dead Zone",
                    helpText: "How much you can move before warning starts. A relaxed dead zone allows more natural movement.",
                    value: $deadZoneSlider,
                    range: 0...4,
                    step: 1,
                    valueLabel: deadZoneLabels[Int(deadZoneSlider)]
                )
                .onChange(of: deadZoneSlider) { newValue in
                    let index = Int(newValue)
                    deadZone = deadZoneValues[index]
                    appDelegate.deadZone = deadZone
                    appDelegate.saveSettings()
                }

                CompactSlider(
                    title: "Intensity",
                    helpText: "How quickly the warning increases as you slouch past the dead zone.",
                    value: $intensitySlider,
                    range: 0...4,
                    step: 1,
                    valueLabel: intensityLabels[Int(intensitySlider)]
                )
                .onChange(of: intensitySlider) { newValue in
                    let index = Int(newValue)
                    intensity = intensityValues[index]
                    appDelegate.intensity = intensity
                    appDelegate.saveSettings()
                }

                CompactSlider(
                    title: "Delay",
                    helpText: "Grace period before warning activates. Allows brief glances at keyboard without triggering.",
                    value: $warningOnsetDelay,
                    range: 0...30,
                    step: 1,
                    valueLabel: "\(Int(warningOnsetDelay))s"
                )
                .onChange(of: warningOnsetDelay) { newValue in
                    appDelegate.warningOnsetDelay = newValue
                    appDelegate.saveSettings()
                }

                CompactSlider(
                    title: "Detection",
                    helpText: "Balance responsiveness vs battery. Responsive detects quickly, Performance saves battery.",
                    value: $detectionModeSlider,
                    range: 0...2,
                    step: 1,
                    valueLabel: detectionModes[Int(detectionModeSlider)].displayName
                )
                .onChange(of: detectionModeSlider) { newValue in
                    let index = Int(newValue)
                    appDelegate.detectionMode = detectionModes[index]
                    appDelegate.saveSettings()
                    appDelegate.applyDetectionMode()
                }
            }
            .padding(.vertical, 10)

            SubtleDivider()

            // Behavior Section - 2 column grid with fixed widths
            VStack(spacing: 6) {
                HStack(spacing: 0) {
                    CompactToggle(
                        title: "Launch at login",
                        helpText: "Automatically start Posturr when you log in",
                        isOn: $launchAtLogin
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: launchAtLogin) { newValue in
                        do {
                            if newValue {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                        } catch {
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }

                    CompactToggle(
                        title: "Show in dock",
                        helpText: "Keep Posturr in Dock and Cmd+Tab",
                        isOn: $showInDock
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: showInDock) { newValue in
                        appDelegate.showInDock = newValue
                        appDelegate.saveSettings()
                        NSApp.setActivationPolicy(newValue ? .regular : .accessory)
                        DispatchQueue.main.async {
                            appDelegate.settingsWindowController.window?.makeKeyAndOrderFront(nil)
                            NSApp.activate(ignoringOtherApps: true)
                        }
                    }
                }

                HStack(spacing: 0) {
                    CompactToggle(
                        title: "Blur when away",
                        helpText: "Apply full blur when you step away",
                        isOn: $blurWhenAway
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: blurWhenAway) { newValue in
                        appDelegate.blurWhenAway = newValue
                        appDelegate.saveSettings()
                    }

                    CompactToggle(
                        title: "Pause on the go",
                        helpText: "Auto-pause on laptop-only display",
                        isOn: $pauseOnTheGo
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: pauseOnTheGo) { newValue in
                        appDelegate.pauseOnTheGo = newValue
                        appDelegate.saveSettings()
                        if !newValue && appDelegate.state == .paused(.onTheGo) {
                            appDelegate.state = .monitoring
                        }
                    }
                }

                // Shortcut row
                HStack(spacing: 0) {
                    CompactShortcutRecorder(
                        shortcut: $toggleShortcut,
                        isEnabled: $toggleShortcutEnabled,
                        onShortcutChange: {
                            appDelegate.toggleShortcutEnabled = toggleShortcutEnabled
                            appDelegate.toggleShortcut = toggleShortcut
                            appDelegate.saveSettings()
                            appDelegate.updateGlobalKeyMonitor()
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                    #if !APP_STORE
                    CompactToggle(
                        title: "Compatibility mode",
                        helpText: "Enable if blur isn't appearing",
                        isOn: $useCompatibilityMode
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onChange(of: useCompatibilityMode) { newValue in
                        appDelegate.useCompatibilityMode = newValue
                        appDelegate.saveSettings()
                        appDelegate.currentBlurRadius = 0
                        for blurView in appDelegate.blurViews {
                            blurView.alphaValue = 0
                        }
                    }
                    #else
                    Spacer()
                        .frame(maxWidth: .infinity)
                    #endif
                }
            }
            .padding(.vertical, 10)
        }
        .padding(16)
        .frame(width: 480)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Social Icons (Official SVG paths from Simple Icons)

struct GitHubIcon: View {
    var color: Color = .secondary

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let scale = min(geometry.size.width, geometry.size.height) / 24

                // Official GitHub Octocat path
                path.move(to: CGPoint(x: 12 * scale, y: 0.297 * scale))
                path.addCurve(to: CGPoint(x: 0 * scale, y: 12.297 * scale),
                              control1: CGPoint(x: 5.37 * scale, y: 0.297 * scale),
                              control2: CGPoint(x: 0 * scale, y: 5.67 * scale))
                path.addCurve(to: CGPoint(x: 8.205 * scale, y: 23.682 * scale),
                              control1: CGPoint(x: 0 * scale, y: 17.6 * scale),
                              control2: CGPoint(x: 3.438 * scale, y: 22.097 * scale))
                path.addCurve(to: CGPoint(x: 9.025 * scale, y: 23.105 * scale),
                              control1: CGPoint(x: 8.805 * scale, y: 23.795 * scale),
                              control2: CGPoint(x: 9.025 * scale, y: 23.424 * scale))
                path.addCurve(to: CGPoint(x: 9.01 * scale, y: 21.065 * scale),
                              control1: CGPoint(x: 9.025 * scale, y: 22.82 * scale),
                              control2: CGPoint(x: 9.01 * scale, y: 22.145 * scale))
                path.addCurve(to: CGPoint(x: 4.968 * scale, y: 19.455 * scale),
                              control1: CGPoint(x: 5.672 * scale, y: 21.789 * scale),
                              control2: CGPoint(x: 4.968 * scale, y: 19.455 * scale))
                path.addCurve(to: CGPoint(x: 3.633 * scale, y: 17.7 * scale),
                              control1: CGPoint(x: 4.422 * scale, y: 18.07 * scale),
                              control2: CGPoint(x: 3.633 * scale, y: 17.7 * scale))
                path.addCurve(to: CGPoint(x: 3.717 * scale, y: 16.971 * scale),
                              control1: CGPoint(x: 2.546 * scale, y: 16.956 * scale),
                              control2: CGPoint(x: 3.717 * scale, y: 16.971 * scale))
                path.addCurve(to: CGPoint(x: 5.555 * scale, y: 18.207 * scale),
                              control1: CGPoint(x: 4.922 * scale, y: 17.055 * scale),
                              control2: CGPoint(x: 5.555 * scale, y: 18.207 * scale))
                path.addCurve(to: CGPoint(x: 9.05 * scale, y: 19.205 * scale),
                              control1: CGPoint(x: 6.625 * scale, y: 20.042 * scale),
                              control2: CGPoint(x: 8.364 * scale, y: 19.512 * scale))
                path.addCurve(to: CGPoint(x: 9.81 * scale, y: 17.6 * scale),
                              control1: CGPoint(x: 9.158 * scale, y: 18.429 * scale),
                              control2: CGPoint(x: 9.467 * scale, y: 17.9 * scale))
                path.addCurve(to: CGPoint(x: 4.344 * scale, y: 11.67 * scale),
                              control1: CGPoint(x: 7.145 * scale, y: 17.3 * scale),
                              control2: CGPoint(x: 4.344 * scale, y: 16.332 * scale))
                path.addCurve(to: CGPoint(x: 5.579 * scale, y: 8.45 * scale),
                              control1: CGPoint(x: 4.344 * scale, y: 10.36 * scale),
                              control2: CGPoint(x: 4.809 * scale, y: 9.14 * scale))
                path.addCurve(to: CGPoint(x: 5.684 * scale, y: 5.274 * scale),
                              control1: CGPoint(x: 5.444 * scale, y: 8.147 * scale),
                              control2: CGPoint(x: 5.039 * scale, y: 6.797 * scale))
                path.addCurve(to: CGPoint(x: 8.984 * scale, y: 6.504 * scale),
                              control1: CGPoint(x: 5.684 * scale, y: 5.274 * scale),
                              control2: CGPoint(x: 6.689 * scale, y: 4.952 * scale))
                path.addCurve(to: CGPoint(x: 12 * scale, y: 6.099 * scale),
                              control1: CGPoint(x: 9.944 * scale, y: 6.237 * scale),
                              control2: CGPoint(x: 10.964 * scale, y: 6.093 * scale))
                path.addCurve(to: CGPoint(x: 15 * scale, y: 6.504 * scale),
                              control1: CGPoint(x: 13.02 * scale, y: 6.105 * scale),
                              control2: CGPoint(x: 14.04 * scale, y: 6.237 * scale))
                path.addCurve(to: CGPoint(x: 18.285 * scale, y: 5.274 * scale),
                              control1: CGPoint(x: 17.28 * scale, y: 4.952 * scale),
                              control2: CGPoint(x: 18.285 * scale, y: 5.274 * scale))
                path.addCurve(to: CGPoint(x: 18.405 * scale, y: 8.45 * scale),
                              control1: CGPoint(x: 18.93 * scale, y: 6.927 * scale),
                              control2: CGPoint(x: 18.645 * scale, y: 8.147 * scale))
                path.addCurve(to: CGPoint(x: 19.635 * scale, y: 11.67 * scale),
                              control1: CGPoint(x: 19.17 * scale, y: 9.29 * scale),
                              control2: CGPoint(x: 19.635 * scale, y: 10.36 * scale))
                path.addCurve(to: CGPoint(x: 14.16 * scale, y: 17.59 * scale),
                              control1: CGPoint(x: 19.635 * scale, y: 16.28 * scale),
                              control2: CGPoint(x: 16.83 * scale, y: 17.29 * scale))
                path.addCurve(to: CGPoint(x: 14.97 * scale, y: 19.81 * scale),
                              control1: CGPoint(x: 14.58 * scale, y: 17.95 * scale),
                              control2: CGPoint(x: 14.97 * scale, y: 18.706 * scale))
                path.addCurve(to: CGPoint(x: 14.955 * scale, y: 23.096 * scale),
                              control1: CGPoint(x: 14.97 * scale, y: 21.416 * scale),
                              control2: CGPoint(x: 14.955 * scale, y: 23.096 * scale))
                path.addCurve(to: CGPoint(x: 15.78 * scale, y: 23.67 * scale),
                              control1: CGPoint(x: 14.955 * scale, y: 23.406 * scale),
                              control2: CGPoint(x: 15.165 * scale, y: 23.783 * scale))
                path.addCurve(to: CGPoint(x: 24 * scale, y: 12.297 * scale),
                              control1: CGPoint(x: 20.565 * scale, y: 22.092 * scale),
                              control2: CGPoint(x: 24 * scale, y: 17.592 * scale))
                path.addCurve(to: CGPoint(x: 12 * scale, y: 0.297 * scale),
                              control1: CGPoint(x: 24 * scale, y: 5.67 * scale),
                              control2: CGPoint(x: 18.63 * scale, y: 0.297 * scale))
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

struct DiscordIcon: View {
    var color: Color = .secondary

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let scale = min(geometry.size.width, geometry.size.height) / 24

                // Official Discord path
                path.move(to: CGPoint(x: 20.317 * scale, y: 4.3698 * scale))
                path.addCurve(to: CGPoint(x: 15.432 * scale, y: 2.8546 * scale),
                              control1: CGPoint(x: 18.7873 * scale, y: 3.6588 * scale),
                              control2: CGPoint(x: 17.1461 * scale, y: 3.1346 * scale))
                path.addCurve(to: CGPoint(x: 14.8237 * scale, y: 4.1041 * scale),
                              control1: CGPoint(x: 15.3535 * scale, y: 2.8917 * scale),
                              control2: CGPoint(x: 15.0347 * scale, y: 3.4793 * scale))
                path.addCurve(to: CGPoint(x: 9.3369 * scale, y: 4.1041 * scale),
                              control1: CGPoint(x: 12.979 * scale, y: 3.8279 * scale),
                              control2: CGPoint(x: 11.1437 * scale, y: 3.8279 * scale))
                path.addCurve(to: CGPoint(x: 8.7192 * scale, y: 2.8546 * scale),
                              control1: CGPoint(x: 9.1269 * scale, y: 3.4793 * scale),
                              control2: CGPoint(x: 8.7963 * scale, y: 2.8917 * scale))
                path.addCurve(to: CGPoint(x: 3.8341 * scale, y: 4.3698 * scale),
                              control1: CGPoint(x: 7.0042 * scale, y: 3.1346 * scale),
                              control2: CGPoint(x: 5.3643 * scale, y: 3.6588 * scale))
                path.addCurve(to: CGPoint(x: 0.5524 * scale, y: 18.0578 * scale),
                              control1: CGPoint(x: 0.5524 * scale, y: 9.0458 * scale),
                              control2: CGPoint(x: -0.3811 * scale, y: 13.5799 * scale))
                path.addCurve(to: CGPoint(x: 6.6052 * scale, y: 21.0872 * scale),
                              control1: CGPoint(x: 2.6052 * scale, y: 19.5654 * scale),
                              control2: CGPoint(x: 4.5939 * scale, y: 20.51 * scale))
                path.addCurve(to: CGPoint(x: 7.8312 * scale, y: 19.093 * scale),
                              control1: CGPoint(x: 7.0668 * scale, y: 20.4568 * scale),
                              control2: CGPoint(x: 7.4862 * scale, y: 19.7878 * scale))
                path.addCurve(to: CGPoint(x: 5.959 * scale, y: 18.2007 * scale),
                              control1: CGPoint(x: 7.179 * scale, y: 18.8454 * scale),
                              control2: CGPoint(x: 6.5569 * scale, y: 18.5483 * scale))
                path.addCurve(to: CGPoint(x: 6.3308 * scale, y: 17.9093 * scale),
                              control1: CGPoint(x: 6.0848 * scale, y: 18.1064 * scale),
                              control2: CGPoint(x: 6.2108 * scale, y: 18.008 * scale))
                path.addCurve(to: CGPoint(x: 12 * scale, y: 19.7026 * scale),
                              control1: CGPoint(x: 8.2586 * scale, y: 19.7026 * scale),
                              control2: CGPoint(x: 10.1508 * scale, y: 19.7026 * scale))
                path.addCurve(to: CGPoint(x: 17.6692 * scale, y: 17.9093 * scale),
                              control1: CGPoint(x: 13.8492 * scale, y: 19.7026 * scale),
                              control2: CGPoint(x: 15.7414 * scale, y: 19.7026 * scale))
                path.addCurve(to: CGPoint(x: 18.041 * scale, y: 18.2007 * scale),
                              control1: CGPoint(x: 17.7892 * scale, y: 18.008 * scale),
                              control2: CGPoint(x: 17.9152 * scale, y: 18.1064 * scale))
                path.addCurve(to: CGPoint(x: 16.1688 * scale, y: 19.093 * scale),
                              control1: CGPoint(x: 17.4431 * scale, y: 18.5483 * scale),
                              control2: CGPoint(x: 16.821 * scale, y: 18.8454 * scale))
                path.addCurve(to: CGPoint(x: 17.3948 * scale, y: 21.0872 * scale),
                              control1: CGPoint(x: 16.5138 * scale, y: 19.7878 * scale),
                              control2: CGPoint(x: 16.9332 * scale, y: 20.4568 * scale))
                path.addCurve(to: CGPoint(x: 23.4476 * scale, y: 18.0578 * scale),
                              control1: CGPoint(x: 19.4061 * scale, y: 20.51 * scale),
                              control2: CGPoint(x: 21.3948 * scale, y: 19.5654 * scale))
                path.addCurve(to: CGPoint(x: 20.317 * scale, y: 4.3698 * scale),
                              control1: CGPoint(x: 24.3811 * scale, y: 13.5799 * scale),
                              control2: CGPoint(x: 23.4476 * scale, y: 9.0458 * scale))
                path.closeSubpath()

                // Left eye
                path.addEllipse(in: CGRect(x: 5.8631 * scale, y: 10.9122 * scale, width: 4.314 * scale, height: 4.838 * scale))

                // Right eye
                path.addEllipse(in: CGRect(x: 13.8369 * scale, y: 10.9122 * scale, width: 4.314 * scale, height: 4.838 * scale))
            }
            .fill(color, style: FillStyle(eoFill: true))
        }
    }
}

// MARK: - Help Button

struct HelpButton: View {
    let text: String
    @State private var showingHelp = false

    var body: some View {
        Button(action: { showingHelp.toggle() }) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingHelp, arrowEdge: .trailing) {
            Text(text)
                .font(.system(size: 11))
                .padding(10)
                .frame(width: 200)
        }
    }
}

// MARK: - Compact Shortcut Recorder

struct CompactShortcutRecorder: View {
    @Binding var shortcut: KeyboardShortcut
    @Binding var isEnabled: Bool
    var onShortcutChange: () -> Void

    @State private var isRecording = false
    @State private var localMonitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .tint(.brandCyan)
                .labelsHidden()
                .scaleEffect(0.65)
                .frame(width: 32)
                .onChange(of: isEnabled) { _ in
                    onShortcutChange()
                }

            Text("Shortcut")
                .font(.system(size: 11))

            HelpButton(text: "Global keyboard shortcut to toggle Posturr. Click the field and press your desired key combination.")

            Button(action: {
                isRecording.toggle()
                if isRecording {
                    startRecording()
                } else {
                    stopRecording()
                }
            }) {
                Text(isRecording ? "Press..." : shortcut.displayString)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(isRecording ? .secondary : (isEnabled ? .primary : .secondary))
                    .lineLimit(1)
                    .frame(width: 60)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(isRecording ? Color.brandCyan.opacity(0.15) : Color.primary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(isRecording ? Color.brandCyan : Color.primary.opacity(0.1), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .frame(height: 22)
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]
            if modifierKeyCodes.contains(event.keyCode) {
                return event
            }

            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let hasModifier = modifiers.contains(.command) || modifiers.contains(.control) ||
                             modifiers.contains(.option) || modifiers.contains(.shift)

            if hasModifier {
                shortcut = KeyboardShortcut(keyCode: event.keyCode, modifiers: modifiers)
                stopRecording()
                onShortcutChange()
                return nil
            }

            return event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}
