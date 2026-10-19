class VoiceStrip < Formula
  desc "Live microphone through a broadcast voice chain, as a virtual microphone"
  homepage "https://github.com/paolomainardi/voice-strip"
  url "https://github.com/paolomainardi/voice-strip/archive/refs/tags/v0.4.0.tar.gz"
  sha256 "01f101eed376fa66a98112165185b76e66544f93a4c8bb3bced15bd66b220339"
  license any_of: ["MIT", "Apache-2.0"]

  depends_on "rust" => :build

  on_macos do
    depends_on arch: :arm64
    depends_on macos: :ventura
  end

  on_linux do
    # libclang generates the PipeWire bindings.
    depends_on "llvm" => :build
    depends_on "pkgconf" => :build
    depends_on "pipewire"
  end

  def install
    (libexec/"post-install").write <<~SH
      #!/bin/sh
      # Re-signs the Voice Strip driver after Homebrew stripped it (macOS).
      [ "$(uname -s)" = Darwin ] || exit 0
      exec /usr/bin/codesign --force --sign - "$1/VoiceStrip.driver"
    SH
    chmod 0755, libexec/"post-install"

    if OS.linux?
      ENV["LIBCLANG_PATH"] = formula_opt_lib("llvm")
      system "cargo", "install", *std_cargo_args(path: "crates/app")
      return
    end

    system "cargo", "install", *std_cargo_args(path: "crates/app")
    system "scripts/macos-driver.sh"

    libexec.install "target/VoiceStrip.driver"
    libexec.install "scripts/macos-driver-install.sh"

    (bin/"voice-strip-install-driver").write <<~SH
      #!/bin/bash
      # Installs (or with --uninstall removes) the Voice Strip virtual microphone.
      if [[ "${1:-}" == "--uninstall" ]]; then
        exec "#{libexec}/macos-driver-install.sh" --uninstall
      fi
      exec "#{libexec}/macos-driver-install.sh" "#{libexec}/VoiceStrip.driver"
    SH
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

        voice-strip-install-driver

      Run it again after an upgrade that changes the driver. Start Voice Strip
      from Terminal the first time, so macOS asks for the microphone permission:

        voice-strip

      Remove the driver before uninstalling the formula:

        voice-strip-install-driver --uninstall
    EOS
  end

  test do
    assert_predicate bin/"voice-strip", :executable?
    assert_match "voice-strip", shell_output("#{bin}/voice-strip --fonts-dir")
    system "codesign", "--verify", "--strict", libexec/"VoiceStrip.driver" if OS.mac?
  end
end
