# macOS DPIManager

A macOS utility to enable HiDPI (Retina scaling) on external monitors, built with SwiftUI and IOKit.

> On recent macOS versions, HiDPI modes at native resolution may not persist after reboot. Apple limits custom overrides on managed displays like the Pro Display XDR to approved presets only - still, give it a try!

---

## Installation

### Homebrew (Recommended)

```bash
brew tap sh4dow-clone/tap
brew install --cask sh4dow-clone/tap/dpimanager
```

If macOS blocks the app on first launch:

```bash
xattr -dr com.apple.quarantine /Applications/DPIManager.app
```

### Manual

1. Download the latest [release](https://github.com/Harsh6628/MAC_DPIManager/releases/download/v1.0.0/DPIManager.zip).
2. Move the `.app` to `/Applications`.
3. Launch it - on first open, macOS may show a security warning.

**Why the warning?** The app isn't notarized because Apple charges $99/year for a Developer Program membership. The warning means "unsigned," not "malicious." The full source is open here.

For HiDPI changes, you'll be prompted for your admin password.

---

## Features

- Detects connected displays using VendorID & ProductID
- Enables and disables HiDPI (Retina scaling) modes
- Supports predefined and custom resolutions
- Adjusts font smoothing settings (-1 through 3)
- Works on Apple Silicon and Intel Macs
- Native SwiftUI interface

---

## Screenshots

<table>
  <tr>
    <td><img width="1000" height="749" alt="DPIManager" src="https://github.com/user-attachments/assets/d31a9ada-1f70-4a0b-b26a-d34b1ce3613e"></td>
  </tr>
</table>

[Watch the tutorial →](https://youtu.be/Bp8UNsP7VDU)

---

## Heads up

- Enabling HiDPI writes override files to `/Library/Displays/Contents/Resources/Overrides`
- Disabling HiDPI removes them
- A reboot is required for changes to take effect

---

## Contributing

Pull requests are welcome. For major changes, open an issue first to discuss what you'd like to change.

---

## Support

DPIManager is free and open source. If it's saved you some time, consider supporting - I'm a student maintaining this in my spare time.

Right now I'm trying to raise **$99 for an Apple Developer Program membership**. That's what it costs to get the app properly signed and notarized - which would eliminate the security warning on install entirely. No more scary popups, no more running `xattr` in the terminal just to open the app.

If you've hit that warning yourself, that's exactly what your support would fix for everyone after you.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/F2F31YNLZ1)

A ⭐ star also helps - it makes the project easier to find for other macOS users who need this.
