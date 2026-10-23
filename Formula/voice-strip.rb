class VoiceStrip < Formula
  desc "Live microphone through a broadcast voice chain, as a virtual microphone"
  homepage "https://github.com/paolomainardi/voice-strip"
  # Release builds from the voice-strip repository: nothing is compiled here.
  if OS.mac?
    url "https://github.com/paolomainardi/voice-strip/releases/download/v0.7.3/voice-strip-v0.7.3-macos-arm64.tar.gz"
    sha256 "6e5b668265474534b9f6ce4e9fe007d9de4f6ea68f0949d3d45ea0071d876da7"
  else
    url "https://github.com/paolomainardi/voice-strip/releases/download/v0.7.3/voice-strip-v0.7.3-linux-x86_64.tar.gz"
    sha256 "ca79d143410b58c887556251c5191dfc76156c2f5abde1efee726a6a564b5027"
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
        Add Voice Strip to your app launcher, with its icon:

          voice-strip app install

        Start Voice Strip, then select "Voice Strip Microphone" as the
        microphone in your call or recording app. It needs a running
        PipeWire session and a Vulkan driver. Remove the launcher before
        uninstalling the formula:

          voice-strip app uninstall
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
