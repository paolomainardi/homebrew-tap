class VoiceStrip < Formula
  desc "Live microphone through a broadcast voice chain, as a virtual microphone"
  homepage "https://github.com/paolomainardi/voice-strip"
  url "https://github.com/paolomainardi/voice-strip/archive/refs/tags/v0.3.1.tar.gz"
  sha256 "fc2639fea719665157d934e21773a0bffce1942201942cbfc2b3a6c1d011e6e7"
  license any_of: ["MIT", "Apache-2.0"]

  depends_on "rust" => :build
  depends_on arch: :arm64
  depends_on macos: :ventura

  def install
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

  # Homebrew strips the driver's executable, which breaks the bundle's seal.
  post_install_steps do
    run "/usr/bin/codesign",
        args:           ["--force", "--sign", "-", "{{libexec}}/VoiceStrip.driver"],
        writable_paths: ["libexec/VoiceStrip.driver"],
        writable_base:  :prefix
  end

  def caveats
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
    system "codesign", "--verify", "--strict", libexec/"VoiceStrip.driver"
  end
end
