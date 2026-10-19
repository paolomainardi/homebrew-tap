# homebrew-tap
Homebrew tap for Voice Strip and other tools by Paolo Mainardi

## Formulae

### voice-strip

[Voice Strip](https://github.com/paolomainardi/voice-strip) makes a live microphone sound like a broadcast voice chain and publishes it as a virtual microphone. It installs the release build on Apple Silicon Macs with macOS 13 or later, and on Linux x86_64 with PipeWire and glibc 2.39 or later.

```bash
brew install paolomainardi/tap/voice-strip
voice-strip driver install   # macOS only
voice-strip
```

On macOS, `voice-strip driver install` installs the virtual microphone. It asks for your password and restarts Core Audio, so audio stops for a moment. Run it again when the app says a release ships a new driver, and run `voice-strip driver uninstall` before `brew uninstall voice-strip`.

Start `voice-strip` from Terminal the first time so macOS asks for the microphone permission. Then select **Voice Strip** (macOS) or **Voice Strip Microphone** (Linux) as the microphone in your call or recording app.
