cask "bluefin-cli" do
  version "0.0.1"
  arch arm: "_arm64", intel: "_amd64"
  os_map = { linux: "linux", macos: "darwin" }

  on_linux do
    on_intel do
      sha256 "42f4d7a8c55bea619a4cb8558af66fa6dcd798e510505f7d48bfafaef4a6ab4c"
    end
    on_arm do
      sha256 "bbc4a2ac38c664849449149fb076d3dc3605898eab6db8dcf565986b25ac781a"
    end
  end

  on_macos do
    on_intel do 
      sha256 "fcfd4bcf9723ad03b9fe1591da286242cf7651ea7b9f7c20f5ec087201cf3815"
    end
    on_arm do
      sha256 "c930feab1acd0fb6bfc632356acb54f56428ee980455f2e358e79f9880a8dca7"
    end
  end

  url "https://github.com/hanthor/bluefin-cli/releases/download/v#{version}/bluefin-cli_#{version}_#{os_map[Homebrew::SimulateSystem.current_os]}#{arch}.tar.gz"
  name "Bluefin CLI"
  desc "Bluefin CLI tool"
  homepage "https://github.com/hanthor/bluefin-cli"

  livecheck do
    url :homepage
    strategy :github_latest
  end

  binary "bluefin-cli"
end
