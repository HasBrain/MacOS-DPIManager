//Code of ContenView.swift

import SwiftUI


struct ContentView: View {
    @StateObject private var displayManager = DisplayManager()
    @State private var selectedDisplay: Display?
    @State private var action: String = "enable"
    @State private var resolution: String = "1920x1200"
    @State private var icon: String = "Default"
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertIsError = false
    @State private var isProcessing = false
    @State private var customResolution: String = ""
    @State private var fontSmoothing: Int = 0
    @State private var showFontSmoothingInfo = false
    @State private var displayFilter: String = ""
    @State private var customWidth: String = ""
    @State private var customHeight: String = ""

    private let resolutions = [
        "1920x1080",
        "1920x1080 (fix underscaled)",
        "1920x1200",
        "2560x1440",
        "3000x2000",
        "3440x1440",
        "Custom"
    ]

    private let icons = [
        "Default",
        "iMac",
        "MacBook",
        "MacBook Pro",
        "LG Display",
        "Pro Display XDR"
    ]

    // MARK: - Design tokens

    private let accent           = Color(red: 10/255,  green: 132/255, blue: 255/255) // macOS system blue
    private let mainBackground   = Color(red: 28/255,  green: 28/255,  blue: 32/255)
    private let surface          = Color(red: 38/255,  green: 38/255,  blue: 44/255)
    private let surfaceElevated  = Color(red: 46/255,  green: 46/255,  blue: 52/255)
    private let hairline         = Color.white.opacity(0.08)
    private let textPrimary      = Color.white.opacity(0.92)
    private let textSecondary    = Color.white.opacity(0.58)
    private let textTertiary     = Color.white.opacity(0.36)

    private struct ResOption {
        let value: String
        let display: String
        let tag: String
    }

    private let resolutionOptions: [ResOption] = [
        .init(value: "1920x1080",                   display: "1920 × 1080", tag: "FHD"),
        .init(value: "1920x1200",                   display: "1920 × 1200", tag: "WUXGA"),
        .init(value: "2560x1440",                   display: "2560 × 1440", tag: "QHD"),
        .init(value: "2560x1600",                   display: "2560 × 1600", tag: "WQXGA"),
        .init(value: "3000x2000",                   display: "3000 × 2000", tag: "3:2"),
        .init(value: "3440x1440",                   display: "3440 × 1440", tag: "UWQHD"),
        .init(value: "3840x2160",                   display: "3840 × 2160", tag: "4K UHD"),
        .init(value: "5120x2880",                   display: "5120 × 2880", tag: "5K"),
        .init(value: "1920x1080 (fix underscaled)", display: "1920 × 1080", tag: "Underscaled fix")
    ]

    private var filteredDisplays: [Display] {
        let trimmed = displayFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return displayManager.displays }
        return displayManager.displays.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Rectangle()
                .fill(hairline)
                .frame(width: 0.5)
            mainPanel
        }
        .frame(minWidth: 720, idealWidth: 760, minHeight: 540, idealHeight: 560)
        .background(mainBackground)
        .preferredColorScheme(.dark)
        .onAppear {
            if selectedDisplay == nil {
                selectedDisplay = displayManager.displays.first
            }
        }
        .onChange(of: displayManager.displays) { _, newValue in
            if selectedDisplay == nil {
                selectedDisplay = newValue.first
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertIsError ? "Operation Failed" : "Operation Complete"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert("Font Smoothing Info", isPresented: $showFontSmoothingInfo) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("""
            Font Smoothing controls how macOS renders text on screen:
            (-1): Use system default
            0: Disable font smoothing
            1: Light font smoothing
            2: Medium font smoothing
            3: Strong font smoothing

            Adjust depending on your display type or personal preference.
            """)
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            // Reserve room for traffic-light controls
            Color.clear.frame(height: 32)

            VStack(spacing: 8) {
                searchField
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)

            displayList

            Rectangle()
                .fill(hairline)
                .frame(height: 0.5)

            refreshButton
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
        }
        .frame(width: 224)
        .background(.ultraThinMaterial)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(textTertiary)
            TextField("Filter displays", text: $displayFilter)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5))
                .foregroundStyle(textPrimary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(hairline, lineWidth: 0.5)
        )
    }

    private var displayList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 1) {
                if displayManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                } else if filteredDisplays.isEmpty {
                    Text(displayManager.displays.isEmpty ? "No displays detected" : "No matches")
                        .font(.system(size: 12))
                        .foregroundStyle(textTertiary)
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(Array(filteredDisplays.enumerated()), id: \.element.id) { idx, display in
                        displayRow(display: display, isMain: idx == 0)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    private func displayRow(display: Display, isMain: Bool) -> some View {
        let isActive = selectedDisplay?.id == display.id
        return Button(action: { selectedDisplay = display }) {
            HStack(spacing: 9) {
                Image(systemName: "display")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isActive ? Color.white : textSecondary)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 1) {
                    Text(display.name)
                        .font(.system(size: 12.5, weight: isActive ? .semibold : .medium))
                        .foregroundStyle(isActive ? Color.white : textPrimary)
                        .lineLimit(1)
                    Text("\(display.vendorID):\(display.productID)")
                        .font(.system(size: 10))
                        .foregroundStyle(isActive ? Color.white.opacity(0.75) : textTertiary)
                }

                Spacer(minLength: 0)

                if isMain {
                    Text("MAIN")
                        .font(.system(size: 8.5, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(isActive ? Color.white : accent)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1.5)
                        .background {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(isActive ? Color.white.opacity(0.22) : accent.opacity(0.15))
                        }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? accent : Color.clear)
            }
            .contentShape(.rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private var refreshButton: some View {
        Button(action: { displayManager.fetchDisplays() }) {
            HStack(spacing: 5) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 10.5, weight: .semibold))
                Text("Refresh Displays")
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .foregroundStyle(textPrimary)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(hairline, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Main panel

    private var mainPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: 38)

            actionSegment
                .padding(.bottom, 22)

            resolutionSection
                .padding(.bottom, 20)

            Rectangle()
                .fill(hairline)
                .frame(height: 0.5)
                .padding(.bottom, 18)

            fontSmoothingSection

            Spacer(minLength: 16)

            bottomActionRow
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(mainBackground)
    }

    // MARK: - Action segment

    private var actionSegment: some View {
        HStack(spacing: 2) {
            segmentButton(title: "Enable HiDPI",  value: "enable")
            segmentButton(title: "Disable HiDPI", value: "disable")
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(hairline, lineWidth: 0.5)
        )
    }

    private func segmentButton(title: String, value: String) -> some View {
        let isActive = action == value
        return Button(action: { action = value }) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(isActive ? Color.white : textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isActive ? accent : Color.clear)
                }
                .contentShape(.rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Resolution

    private var resolutionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Resolution")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6),
                GridItem(.flexible(), spacing: 6)
            ], spacing: 6) {
                ForEach(resolutionOptions, id: \.value) { opt in
                    resolutionPill(opt: opt)
                }
            }

            customRow
                .padding(.top, 4)
        }
    }

    private func resolutionPill(opt: ResOption) -> some View {
        let isActive = (resolution == opt.value) && customResolution.isEmpty
        return Button(action: {
            resolution = opt.value
            customResolution = ""
            customWidth = ""
            customHeight = ""
        }) {
            VStack(spacing: 2) {
                Text(opt.display)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(isActive ? Color.white : textPrimary)
                Text(opt.tag)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(isActive ? Color.white.opacity(0.78) : textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(isActive ? accent : surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(isActive ? Color.clear : hairline, lineWidth: 0.5)
            )
            .contentShape(.rect(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    private var customRow: some View {
        HStack(spacing: 7) {
            Image(systemName: "pencil")
                .font(.system(size: 10.5))
                .foregroundStyle(textTertiary)

            customSizeField(placeholder: "Width", text: $customWidth)

            Text("×")
                .font(.system(size: 12))
                .foregroundStyle(textTertiary)

            customSizeField(placeholder: "Height", text: $customHeight)

            Text("Custom")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(textTertiary)

            Spacer()
        }
        .onChange(of: customWidth)  { _, _ in syncCustomResolution() }
        .onChange(of: customHeight) { _, _ in syncCustomResolution() }
    }

    private func customSizeField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(.system(size: 12))
            .foregroundStyle(textPrimary)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .frame(maxWidth: 92)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(hairline, lineWidth: 0.5)
            )
    }

    private func syncCustomResolution() {
        let w = customWidth.trimmingCharacters(in: .whitespacesAndNewlines)
        let h = customHeight.trimmingCharacters(in: .whitespacesAndNewlines)
        if !w.isEmpty && !h.isEmpty {
            customResolution = "\(w)x\(h)"
        } else {
            customResolution = ""
        }
    }

    // MARK: - Font smoothing

    private var fontSmoothingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                sectionLabel("Font Smoothing")
                Button(action: { showFontSmoothingInfo = true }) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(textTertiary)
                }
                .buttonStyle(.plain)
                .help("What is Font Smoothing?")
            }

            HStack(spacing: 5) {
                ForEach([-1, 0, 1, 2, 3], id: \.self) { val in
                    fontSmoothingButton(val)
                }
                setButton
            }
        }
    }

    private func fontSmoothingButton(_ val: Int) -> some View {
        let isActive = fontSmoothing == val
        return Button(action: { fontSmoothing = val }) {
            Text("\(val)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isActive ? Color.white : textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isActive ? accent : surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(isActive ? Color.clear : hairline, lineWidth: 0.5)
                )
                .contentShape(.rect(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    private var setButton: some View {
        Button(action: {
            isProcessing = true
            displayManager.applyFontSmoothing(value: fontSmoothing) { success, message in
                isProcessing = false
                alertMessage = message
                alertIsError = !success
                showAlert = true
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                Text("Set")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(textPrimary)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7)
                    .stroke(hairline, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom row

    private var bottomActionRow: some View {
        HStack(spacing: 8) {
            Button(action: {
                displayManager.checkFontSmoothing { currentValue in
                    alertMessage = "Current AppleFontSmoothing value: \(currentValue)"
                    alertIsError = false
                    showAlert = true
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "eye")
                        .font(.system(size: 11.5, weight: .medium))
                    Text("Check")
                        .font(.system(size: 12.5, weight: .medium))
                }
                .foregroundStyle(textPrimary)
                .padding(.vertical, 9)
                .padding(.horizontal, 22)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(surfaceElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(hairline, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)

            Button(action: applySettings) {
                Group {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.65)
                    } else {
                        Text(action == "enable" ? "Enable HiDPI" : "Disable HiDPI")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(accent.opacity(selectedDisplay == nil ? 0.4 : 1.0))
                )
            }
            .buttonStyle(.plain)
            .disabled(selectedDisplay == nil || isProcessing)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.9)
            .foregroundStyle(textTertiary)
    }

    private func applySettings() {
        guard let display = selectedDisplay else { return }

        let finalResolution = customResolution.isEmpty ? resolution : customResolution

        isProcessing = true
        displayManager.applySettings(
            display: display,
            action: action,
            resolution: finalResolution,
            icon: icon
        ) { success, message in
            isProcessing = false
            alertMessage = message
            alertIsError = !success
            showAlert = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
