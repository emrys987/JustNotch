# JustNotch

**JustNotch** is a sleek, lightweight, and modern macOS companion that transforms your MacBook's hardware notch into an interactive Dynamic Island for media playback, focus timer, clipboard history, and file shelf.

This is a **100% free, open-source, and non-profit** project developed with the assistance of AI.

---

## Features

- **Music & Live Synced Lyrics:**
  - Integrates seamlessly with **Spotify** and **Apple Music**.
  - Displays mini album art directly on the notch when closed.
  - View synchronized karaoke-style lyrics inline directly within the notch without window shifting.

- **Pomodoro Focus Timer:**
  - Beautiful circular progress ring matching the album art scale.
  - One-tap start, pause, and reset controls built right inside the timer.

- **Clipboard History:**
  - Keeps track of recently copied text and images as horizontal cards.
  - Pin important items to the left, delete, or re-copy with a single click.

- **Drop Shelf:**
  - Drag and drop files or notes directly over the notch to hold them temporarily.
  - The notch automatically expands and switches to the shelf when a file is dragged over it.
  - Zero Data Retention (ZDR): files are kept purely locally on your machine and can be cleared with one click.

- **Customizable Appearance:**
  - Choose between Apple-style Frosted Glass, Solid OLED Black, Custom Colors, or your own Background Image (with zoom, pan, and blur controls).
  - Multi-language support (English & Turkish).

---

## ⚠️ Important Note: macOS Gatekeeper ("Malware" / "Unidentified Developer" Warning)

When opening **JustNotch** for the first time, macOS may show a warning saying:
> *"JustNotch cannot be opened because Apple cannot check it for malicious software"* or *"JustNotch is damaged and can't be opened."*

### Why does this happen?
This project is completely **free and non-profit**. Because of this, it is not signed with a paid $99/year Apple Developer Certificate. macOS automatically flags any downloaded application from an unverified developer as potential malware by default. **The entire source code is completely open and safe to review.**

### How to open the app (Choose either method):

#### Method 1: Through System Settings (Easiest)
1. Double-click the app. If a warning appears, click **Cancel** or **OK**.
2. Open **System Settings** on your Mac.
3. Go to **Privacy & Security** and scroll down to the **Security** section.
4. You will see: *"JustNotch was blocked from use because it is not from an identified developer."*
5. Click **Open Anyway**, confirm with your password or Touch ID, and click **Open**.

*(You only need to do this once. The app will open normally from then on).*

#### Method 2: Via Terminal (Quickest)
If you placed the app in your Applications folder, open Terminal and run:
```bash
xattr -cr /Applications/JustNotch.app
```
*(If the app is still in your Downloads folder, run: `xattr -cr ~/Downloads/JustNotch.app`)*

---

## How to Use

- **Open / Close Notch:** Hover your mouse over the hardware notch, or click it. Press the up-chevron icon or move your mouse away to collapse.
- **View Lyrics:** Click the current lyric line while a song is playing to enter full inline lyrics mode.
- **Settings:** Press `Cmd + ,` or click the gear icon in the notch header or the **JustNotch** icon in your macOS menu bar.

---

## Building from Source

If you want to build the project yourself:

1. Clone this repository:
   ```bash
   git clone https://github.com/emrys987/JustNotch.git
   cd JustNotch
   ```
2. Run the build script:
   ```bash
   ./build_app.sh
   ```
3. Open the newly built application:
   ```bash
   open JustNotch.app
   ```

---

## License

This project is open-source and free for personal use under the MIT License.
