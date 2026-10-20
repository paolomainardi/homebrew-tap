class VoiceStrip < Formula
  desc "Live microphone through a broadcast voice chain, as a virtual microphone"
  homepage "https://github.com/paolomainardi/voice-strip"
  # Release builds from the voice-strip repository: nothing is compiled here.
  if OS.mac?
    url "https://github.com/paolomainardi/voice-strip/releases/download/v0.7.0/voice-strip-v0.7.0-macos-arm64.tar.gz"
    sha256 "ce4df8becb3b6e213c798c82e269cc27f8607fe3c93a07fa99c2ced5038a3d2a"
  else
    url "https://github.com/paolomainardi/voice-strip/releases/download/v0.7.0/voice-strip-v0.7.0-linux-x86_64.tar.gz"
    sha256 "7bfb74f8f89a5d0beb23096083465b9222189ddf15f5934f97e5f9e53359a585"
  end
  license any_of: ["MIT", "Apache-2.0"]

  on_macos do
    depends_on arch: :arm64
    depends_on macos: :ventura
  end

  on_linux do
    # The binary links the system PipeWire library and needs glibc 2.39 or later.
    depends_on arch: :x86_64
  end

  def install
    if OS.mac?
      # The binary lives inside the app bundle, so macOS shows "Voice Strip"
      # with its icon. `voice-strip driver install` finds the driver in libexec.
      prefix.install "Voice Strip.app"
      bin.install_symlink prefix/"Voice Strip.app/Contents/MacOS/voice-strip"
      libexec.install "VoiceStrip.driver"
    else
      bin.install "voice-strip"
    end

    (libexec/"post-install").write <<~SH
      #!/bin/sh
      # Re-signs the Voice Strip app and driver ad-hoc after Homebrew stripped
      # their binaries (macOS).
      [ "$(uname -s)" = Darwin ] || exit 0
      /usr/bin/codesign --force --sign - "$1/Voice Strip.app" || exit 1
      exec /usr/bin/codesign --force --sign - "$1/libexec/VoiceStrip.driver"
    SH
    chmod 0755, libexec/"post-install"
  end

  # Homebrew strips the executables, which breaks the bundles' seals: the
  # helper re-signs them on macOS and does nothing on Linux.
  post_install_steps do
    run "{{libexec}}/post-install",
        args:           ["{{prefix}}"],
        writable_paths: ["Voice Strip.app", "libexec"],
        writable_base:  :prefix
  end

  def caveats
    if OS.linux?
      return <<~EOS
        Start Voice Strip, then select "Voice Strip Microphone" as the
        microphone in your call or recording app:

          voice-strip

        It needs a running PipeWire session and a Vulkan driver.
      EOS
    end

    <<~EOS
      Install the virtual microphone once (asks for your password and
      restarts Core Audio, so audio stops for a moment):

        voice-strip driver install

      Add Voice Strip to your Applications folder, so Spotlight and Launchpad
      can open it:

        voice-strip app install

      After an upgrade, run `voice-strip app install` again to refresh that
      copy. The app says when a release ships a new driver: run
      `voice-strip driver install` again. Open Voice Strip from Spotlight, or
      run `voice-strip` in Terminal.

      Remove the app copy and the driver before uninstalling the formula:

        voice-strip app uninstall
        voice-strip driver uninstall
    EOS
  end

  test do
    assert_match "voice-strip", shell_output("#{bin}/voice-strip --fonts-dir")
    if OS.mac?
      system "codesign", "--verify", "--strict", prefix/"Voice Strip.app"
      system "codesign", "--verify", "--strict", libexec/"VoiceStrip.driver"
      assert_match "(revision ", shell_output("#{bin}/voice-strip driver status || true")
    end
  end
end
