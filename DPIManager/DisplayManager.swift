import Foundation
import CoreGraphics
import IOKit
import IOKit.graphics
import AppKit

class DisplayManager: ObservableObject {
    @Published var displays: [Display] = []
    @Published var isLoading = false
    @Published var message = ""

    init() {
        fetchDisplays()
    }

    func fetchDisplays() {
        isLoading = true
        message = "Detecting displays..."

        DispatchQueue.global(qos: .userInitiated).async {
            let newDisplays = self.getConnectedDisplays()

            DispatchQueue.main.async {
                self.displays = newDisplays
                self.isLoading = false
                if newDisplays.isEmpty {
                    self.message = "No displays found"
                } else {
                    self.message = "Found \(newDisplays.count) display(s)"
                }
            }
        }
    }

    private func getConnectedDisplays() -> [Display] {
        var displayCount: UInt32 = 0
        var displays: [Display] = []
        var result = CGGetActiveDisplayList(0, nil, &displayCount)
        if result != .success {
            print("Error detecting displays: \(result.rawValue)")
            return []
        }

        var activeDisplays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        result = CGGetActiveDisplayList(displayCount, &activeDisplays, &displayCount)
        if result != .success {
            print("Error retrieving displays: \(result.rawValue)")
            return []
        }

        for (index, displayID) in activeDisplays.enumerated() {
            let vendorID = CGDisplayVendorNumber(displayID)
            let productID = CGDisplayModelNumber(displayID)

            let name = getDisplayName(displayID: displayID) ?? "Display \(CGDisplayPixelsWide(displayID))x\(CGDisplayPixelsHigh(displayID))"

            let display = Display(
                id: "\(vendorID)-\(productID)",
                index: index,
                vendorID: String(format: "%04x", vendorID),
                productID: String(format: "%04x", productID),
                name: name,
                isAppleSilicon: DisplayManager.isAppleSiliconMac
            )

            displays.append(display)
        }

        return displays
    }

    private func getDisplayName(displayID: CGDirectDisplayID) -> String? {
        // Modern public API — works on Apple Silicon and Intel.
        // Returns the marketing/EDID name (e.g. "Samsung", "BenQ ").
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
               CGDirectDisplayID(screenNumber.uint32Value) == displayID {
                let name = screen.localizedName
                if !name.isEmpty {
                    return name
                }
            }
        }

        // Legacy IOKit fallback — works on Intel Macs running older macOS.
        var servicePortIterator = io_iterator_t()
        let matching = IOServiceMatching("IODisplayConnect")
        let kernResult = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &servicePortIterator)
        if kernResult != KERN_SUCCESS {
            return nil
        }

        var service = IOIteratorNext(servicePortIterator)
        while service != 0 {
            let infoDict = IODisplayCreateInfoDictionary(service, UInt32(kIODisplayOnlyPreferredName)).takeRetainedValue() as NSDictionary

            if let vendorID = infoDict[kDisplayVendorID] as? UInt32,
               let productID = infoDict[kDisplayProductID] as? UInt32 {
                if CGDisplayVendorNumber(displayID) == vendorID,
                   CGDisplayModelNumber(displayID) == productID {
                    if let productNameDict = infoDict["DisplayProductName"] as? NSDictionary,
                       let displayName = productNameDict.allValues.first as? String {
                        IOObjectRelease(service)
                        IOObjectRelease(servicePortIterator)
                        return displayName
                    }
                }
            }

            IOObjectRelease(service)
            service = IOIteratorNext(servicePortIterator)
        }
        IOObjectRelease(servicePortIterator)
        return nil
    }

    // ✅ New platform detection property
    static var isAppleSiliconMac: Bool {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machineMirror = Mirror(reflecting: sysinfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.contains("arm64")
    }

    
    func checkFontSmoothing(completion: @escaping (Int) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
            task.arguments = ["-currentHost", "read", "-g", "AppleFontSmoothing"]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                DispatchQueue.main.async { completion(-1) }
                return
            }

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Not set"

            DispatchQueue.main.async {
                if let intValue = Int(output) {
                    completion(intValue)
                } else {
                    completion(-1)
                }
            }
        }
    }

    func applyFontSmoothing(value: Int, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
            task.arguments = ["-currentHost", "write", "-g", "AppleFontSmoothing", "-int", "\(value)"]

            do {
                try task.run()
                task.waitUntilExit()
            } catch {
                DispatchQueue.main.async {
                    completion(false, "Failed to launch defaults.")
                }
                return
            }

            DispatchQueue.main.async {
                if task.terminationStatus == 0 {
                    completion(true, "Font smoothing set to \(value). Please log out and log back in to apply changes.")
                } else {
                    completion(false, "Failed to set font smoothing.")
                }
            }
        }
    }



    func applySettings(display: Display, action: String, resolution: String, icon: String, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if action == "enable" {
                    try self.enableHiDPI(display: display, resolution: resolution, icon: icon)
                    DispatchQueue.main.async {
                        completion(true, "HiDPI enabled for \(display.name). Please reboot to apply changes. You may uninstall this app.")
                    }
                } else {
                    try self.disableHiDPI(display: display)
                    DispatchQueue.main.async {
                        completion(true, "HiDPI disabled for \(display.name). Please reboot to apply changes. You may uninstall this app.")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    private func enableHiDPI(display: Display, resolution: String, icon: String) throws {
        let targetDir = "/Library/Displays/Contents/Resources/Overrides"
        let displayDir = "\(targetDir)/DisplayVendorID-\(display.vendorID)"
        let displayFile = "\(displayDir)/DisplayProductID-\(display.productID)"

        // Generate resolution data
        let resolutionData = try generateResolutionData(resolution: resolution)

        // Create the display override plist content
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
            <dict>
                <key>DisplayProductID</key>
                <integer>\(Int(display.productID, radix: 16) ?? 0)</integer>
                <key>DisplayVendorID</key>
                <integer>\(Int(display.vendorID, radix: 16) ?? 0)</integer>
                <key>scale-resolutions</key>
                <array>
        \(resolutionData)
                </array>
                <key>target-default-ppmm</key>
                <real>10.0699301</real>
            </dict>
        </plist>
        """

        // Write the plist to a private per-invocation temp directory (mode 0700).
        // Path is intentionally clean (no spaces / parens) so the elevated shell can read it.
        let workDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("DPIManager-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: workDir,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        defer { try? FileManager.default.removeItem(at: workDir) }

        let tempFile = workDir.appendingPathComponent("override.plist").path
        try plistContent.write(to: URL(fileURLWithPath: tempFile), atomically: true, encoding: .utf8)

        // Combine all privileged shell commands into one script
        let fullScript = """
        mkdir -p "\(displayDir)"
        cp "\(tempFile)" "\(displayFile)"
        chown root:wheel "\(displayFile)"
        chmod 644 "\(displayFile)"
        rm "\(tempFile)"
        defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool YES
        """

        // Run all at once
        try executeShellCommand(fullScript)
    }

    
    private func disableHiDPI(display: Display) throws {
        let targetDir = "/Library/Displays/Contents/Resources/Overrides"
        let displayDir = "\(targetDir)/DisplayVendorID-\(display.vendorID)"
        
        let removeScript = """
        rm -rf "\(displayDir)"
        """
        
        try executeShellCommand(removeScript)
    }
    
    private func generateResolutionData(resolution: String) throws -> String {
        var resolutionArray: [String] = []
        
        // Handle custom resolution input (can be multiple resolutions separated by spaces or commas)
        if resolution.contains("x") && !["1920x1080", "1920x1080 (fix underscaled)", "1920x1200", "2560x1440", "3000x2000", "3440x1440"].contains(resolution) {
            // Parse multiple custom resolutions
            let customResolutions = resolution
                .replacingOccurrences(of: ",", with: " ") // Replace commas with spaces
                .components(separatedBy: " ") // Split by spaces
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } // Trim whitespace
                .filter { !$0.isEmpty } // Remove empty strings
            
            for customRes in customResolutions {
                let parts = customRes.components(separatedBy: "x")
                // Cap at 16384 so width*2/height*2 can't overflow Int and crash.
                guard parts.count == 2,
                      let width = Int(parts[0]),
                      let height = Int(parts[1]),
                      (1...16384).contains(width),
                      (1...16384).contains(height) else {
                    throw NSError(domain: "HiDPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid resolution '\(customRes)'. Use WIDTHxHEIGHT with each value between 1 and 16384 (e.g., 1856x1044)."])
                }
                resolutionArray.append(customRes)
            }
        } else {
            // Handle predefined resolutions
            switch resolution {
            case "1920x1080":
                resolutionArray = ["1680x945", "1440x810", "1280x720", "1024x576"]
            case "1920x1080 (fix underscaled)":
                resolutionArray = ["1680x945", "1424x802", "1280x720", "1024x576"]
            case "1920x1200":
                resolutionArray = ["1920x1200", "1680x1050", "1440x900", "1280x800", "1024x640"]
            case "2560x1440":
                resolutionArray = ["2560x1440", "2048x1152", "1920x1080", "1680x945", "1440x810", "1280x720"]
            case "3000x2000":
                resolutionArray = ["3000x2000", "2880x1920", "2250x1500", "1920x1280", "1680x1050", "1440x900", "1280x800"]
            case "3440x1440":
                resolutionArray = ["3440x1440", "2752x1152", "2580x1080", "2365x990", "1935x810", "1720x720"]
            default:
                throw NSError(domain: "HiDPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid resolution format"])
            }
        }
        
        var dataEntries: [String] = []
        
        for res in resolutionArray {
            let components = res.split(separator: "x")
            guard components.count == 2,
                  let width = Int(components[0]),
                  let height = Int(components[1]) else {
                continue
            }
            
            // Generate HiDPI data (double the resolution)
            let hidpiWidth = width * 2
            let hidpiHeight = height * 2
            
            // Convert to hex and create base64 encoded data
            let widthHex = String(format: "%08x", hidpiWidth)
            let heightHex = String(format: "%08x", hidpiHeight)
            let hexString = widthHex + heightHex
            
            if let data = Data(hex: hexString) {
                let base64String = data.base64EncodedString()
                dataEntries.append("                <data>\(base64String)AAAAB</data>")
                dataEntries.append("                <data>\(base64String)AAAABACAAAA==</data>")
            }
        }
        
        return dataEntries.joined(separator: "\n")
    }
    
    private func executeShellCommand(_ command: String) throws {
        let script = """
        #!/bin/bash
        \(command)
        """

        // Use a private per-invocation temp directory (mode 0700) with a clean path
        // (no spaces / parens), so the elevated bash invocation works without quoting gymnastics.
        let workDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("DPIManager-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: workDir,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        defer { try? FileManager.default.removeItem(at: workDir) }

        let tempScript = workDir.appendingPathComponent("hidpi_script.sh").path
        try script.write(to: URL(fileURLWithPath: tempScript), atomically: true, encoding: .utf8)

        // Defense-in-depth: still use AppleScript's `quoted form of` so that any future
        // path with special characters (e.g. a user home directory with spaces) remains safe.
        let appleScript = "do shell script (\"bash \" & quoted form of \"\(tempScript)\") with administrator privileges"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", appleScript]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "HiDPI", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: output])
        }
    }
}

// Extension to create Data from hex string
extension Data {
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        var index = hex.startIndex
        for _ in 0..<len {
            let nextIndex = hex.index(index, offsetBy: 2)
            if let b = UInt8(hex[index..<nextIndex], radix: 16) {
                data.append(b)
            } else {
                return nil
            }
            index = nextIndex
        }
        self = data
    }
}
