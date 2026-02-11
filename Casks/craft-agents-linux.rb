cask "craft-agents-linux" do
  arch intel: "x64"

  version "0.4.3"
  sha256 x86_64_linux: "e7bc0b62eafe4701aa1924933ddefca03f5ddbf2147d3c2414397079272d21fd"

  url "https://github.com/lukilabs/craft-agents-oss/releases/download/v#{version}/Craft-Agents-#{version}-linux-x64.AppImage"
    verified: "github.com/lukilabs/craft-agents-oss"
  name "Craft Agents"
  desc "Work with most powerful agents in the world, with the UX they deserve"
  homepage "https://agents.craft.do/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on formula: "squashfs"

  binary "squashfs-root/@craft-agentelectron", target: "craft-agents"
  artifact "squashfs-root/@craft-agentelectron.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/@craft-agentelectron.png"
  artifact "squashfs-root/@craft-agentelectron.desktop",
           target: "#{Dir.home}/.local/share/applications/@craft-agentelectron.desktop"

  preflight do
    appimage_path = "#{staged_path}/Craft-Agents-#{version}-linux-x64.AppImage"
    system "chmod", "+x", appimage_path
    system appimage_path, "--appimage-extract", chdir: staged_path
    FileUtils.rm_f appimage_path
  end

  postflight do
    desktop_target = "#{Dir.home}/.local/share/applications/@craft-agentelectron.desktop"
    if File.exist?(desktop_target)
      desktop_content = File.read(desktop_target)
      desktop_content.gsub!(/^Exec=AppRun/, "Exec=#{HOMEBREW_PREFIX}/bin/craft-agents")
      desktop_content.gsub!(/^Icon=.*/, "Icon=#{Dir.home}/.local/share/icons/hicolor/512x512/apps/@craft-agentelectron.png")
      File.write(desktop_target, desktop_content)
    end
  end

  uninstall_postflight do
    FileUtils.rm_f("#{Dir.home}/.local/share/icons/hicolor/512x512/apps/@craft-agentelectron.png")
    FileUtils.rm_f("#{Dir.home}/.local/share/applications/@craft-agentelectron.desktop")
  end

  zap trash: [
    "~/.config/Craft Agents",
    "~/.craft-agent",
  ]
end

