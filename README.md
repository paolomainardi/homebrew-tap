# homebrew-tap
Homebrew tap for Voice Strip and other tools by Paolo Mainardi

## Formulae

### voice-strip

[Voice Strip](https://github.com/paolomainardi/voice-strip) makes a live microphone sound like a broadcast voice chain and publishes it as a virtual microphone. Apple Silicon Macs on macOS 13 or later, and Linux (x86_64 and arm64) with PipeWire.

```bash
brew install paolomainardi/tap/voice-strip
voice-strip-install-driver
voice-strip
```

`voice-strip-install-driver` installs the virtual microphone. It asks for your password and restarts Core Audio, so audio stops for a moment. Run it again after an upgrade that changes the driver, and run `voice-strip-install-driver --uninstall` before `brew uninstall voice-strip`.

Start `voice-strip` from Terminal the first time so macOS asks for the microphone permission. Then select **Voice Strip** as the microphone in your call or recording app.

Bottles are built for macOS 26 (Tahoe). On older macOS versions brew builds from source, which needs Rust and takes a few minutes.
