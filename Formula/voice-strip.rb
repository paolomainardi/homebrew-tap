class VoiceStrip < Formula
  desc "Live microphone through a broadcast voice chain, as a virtual microphone"
  homepage "https://github.com/paolomainardi/voice-strip"
  # Release builds from the voice-strip repository: nothing is compiled here.
  if OS.mac?
    url "https://github.com/paolomainardi/voice-strip/releases/download/v0.6.0/voice-strip-v0.6.0-macos-arm64.tar.gz"
    sha256 "1a973c3ef366f08a00a8987451be363d1409cf876f8fa27efd3cb116231498bd"
  else
    url "https://github.com/paolomainardi/voice-strip/releases/download/v0.6.0/voice-strip-v0.6.0-linux-x86_64.tar.gz"
    sha256 "4ed9ff6933e2fa19cf10c5c8c7139f385936e112168dd6121de295bc5a6c36aa"
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
    bin.install "voice-strip"
    # `voice-strip driver install` finds the driver in libexec.
    libexec.install "VoiceStrip.driver" if OS.mac?

    (libexec/"post-install").write <<~SH
      #!/bin/sh
      # Re-signs the Voice Strip driver ad-hoc after Homebrew stripped it (macOS).
      [ "$(uname -s)" = Darwin ] || exit 0
      exec /usr/bin/codesign --force --sign - "$1/VoiceStrip.driver"
    SH
    chmod 0755, libexec/"post-install"
  end

  # Homebrew strips the driver's executable, which breaks the bundle's seal:
  # the helper re-signs it on macOS and does nothing on Linux.
  post_install_steps do
    run "{{libexec}}/post-install",
        args:           ["{{libexec}}"],
        writable_paths: ["libexec"],
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

      After an upgrade, the app says when a release ships a new driver: run
      the same command again. Start Voice Strip from Terminal the first time,
      so macOS asks for the microphone permission:

        voice-strip

      Remove the driver before uninstalling the formula:

        voice-strip driver uninstall
    EOS
  end

  test do
    assert_match "voice-strip", shell_output("#{bin}/voice-strip --fonts-dir")
    if OS.mac?
      system "codesign", "--verify", "--strict", libexec/"VoiceStrip.driver"
      assert_match "(revision ", shell_output("#{bin}/voice-strip driver status || true")
    end
  end
end
