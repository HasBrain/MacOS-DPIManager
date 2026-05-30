# MAC_DPIManager

A native macOS utility to enable or disable HiDPI (Retina scaling) display modes on external monitors.  
Built with **SwiftUI** and **IOKit**, this app makes it easy to manage display resolutions, and apply font smoothing preferences — all through a modern, clean GUI.


> Note: On recent macOS updates, HiDPI modes matching a display’s native resolution (especially on Apple displays like the Pro Display XDR) may not appear after reboot. macOS typically offers HiDPI scaling only for resolutions below native and may reject custom overrides on managed displays like the Pro Display XDR, limiting options to Apple-approved presets

## 📸 Features

- 🖥️ Detect connected displays with VendorID & ProductID.
- 📏 Enable **HiDPI (Retina scaling)** modes for selected displays.
- 📝 Support for **predefined** and **custom resolutions**.
- 🎨 Optional selection of display icons.
- 🔠 Adjust **Font Smoothing** settings (-1, 0, 1, 2, 3) on the fly.
- 💻 Supports both **Apple Silicon (arm64)** and **Intel Macs**.
- 🔐 Runs required privileged commands safely via `osascript` authentication prompts.
- 📦 Clean, native **SwiftUI** interface.

## 📥 Installation

### 🍺 Via Homebrew (Recommended)

```bash
brew tap 0xDranzer/tap
brew install --cask 0xdranzer/tap/dpimanager
```

> If macOS blocks the app on first launch, run:
> ```bash
> xattr -dr com.apple.quarantine /Applications/DPIManager.app
> `

### 🖐 Manual

1. Download the latest [release](https://github.com/Harsh6628/MAC_DPIManager/releases/download/v1.0.0/DPIManager.zip).
2. Extract & Move the `.app` bundle to your `/Applications` folder.
3. Launch the app — you may need to grant permissions to run it the first time.
> ⚠️ **Important**
>
> This step is necessary because the app has not been notarized by Apple due to the membership fees of the Apple Developer Program.  
> If you see a message like  **“Apple could not verify ‘DPIManager.app’ is free of malware”**, it refers to the **lack of notarization**, not to any detected issues or anomalies.

4. For enabling/disabling HiDPI, you’ll be prompted for your administrator password.

## Usage
<table>
  <tr>
    <td><img width="516" height="749" alt="DPIManager" src="https://github.com/user-attachments/assets/4e378d6b-63a1-45dc-ac21-1d89e0ffe4d0"></td>
    <td><img width="516" height="749" alt="DPIManager-2" src="https://github.com/user-attachments/assets/647fe268-40c2-40a7-91f9-5130a9b865ca"></td>
  </tr>
</table>


## Tutorial Video

Please watch this video: https://youtu.be/kmteq305lV8

## ⚠️ Warnings

- **Enabling HiDPI creates override files in `/Library/Displays/Contents/Resources/Overrides`.**
- **Disabling HiDPI removes those override files.**
- A **system reboot is required** for changes to take effect.

Pull requests are welcome!  
For major changes, please open an issue first to discuss what you would like to change.

## ⭐️ If you like this project — consider giving it a star!

I’m building this tool to make macOS display management simpler and more accessible for everyone. Your support helps me continue maintaining and improving it.

I’m also currently working toward covering my education expenses, so every contribution genuinely makes a difference.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/F2F31YNLZ1)
