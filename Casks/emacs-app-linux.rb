cask "emacs-app-linux" do
  arch arm: "arm64", intel: "amd64"

  version "30.2-17"
  sha256 arm64_linux:  "315a949a66d396003bb3ac4780d68aebaf5603ed9ade35711924a576ef4ae4b3",
         x86_64_linux: "144f0e541cc2ebf65027004a65f521b38cc6ee9e729183813536682dcbe16014"

  url "https://github.com/daegalus/linux-app-builds/releases/download/emacs-pgtk-#{version}/emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}.tar.gz",
      verified: "github.com/daegalus/linux-app-builds/"
  name "Emacs PGTK"
  desc "Text editor with PGTK support (Native Wayland and X11)"
  homepage "https://github.com/daegalus/linux-app-builds"

  livecheck do
    url :url
    regex(/^emacs-pgtk[._-]v?(\d+(?:\.\d+)+-\d+)$/i)
  end

  # Binaries
  binary "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/run-emacs.sh", target: "emacs"
  binary "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/bin/emacs-#{version.major_minor}", target: "emacs-#{version.major_minor}"
  binary "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/bin/emacsclient"
  binary "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/bin/ctags"
  binary "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/bin/ebrowse"
  binary "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/bin/etags"

  # Libraries (needed for emacs to run)
  artifact "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/lib",
           target: "#{HOMEBREW_PREFIX}/opt/emacs-app-linux/lib"

  # Share directory (elisp, icons, schemas, man pages, etc.)
  artifact "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/share",
           target: "#{HOMEBREW_PREFIX}/opt/emacs-app-linux/share"

  # Libexec (helper binaries and compiled modules)
  artifact "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/libexec",
           target: "#{HOMEBREW_PREFIX}/opt/emacs-app-linux/libexec"

  # Man pages
  manpage "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/share/man/man1/ctags.1.gz"
  manpage "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/share/man/man1/ebrowse.1.gz"
  manpage "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/share/man/man1/emacs.1.gz"
  manpage "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/share/man/man1/emacsclient.1.gz"
  manpage "emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/share/man/man1/etags.1.gz"

  preflight do
    # Make run-emacs.sh executable
    FileUtils.chmod "+x", "#{staged_path}/emacs-pgtk-#{version.major_minor}-ubuntu-lts-#{arch}/run-emacs.sh"
  end

  postflight do
    # Create necessary directories
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons/hicolor"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/glib-2.0/schemas"

    emacs_root = "#{HOMEBREW_PREFIX}/opt/emacs-app-linux"

    # Copy compiled gschemas
    if File.exist?("#{emacs_root}/share/glib-2.0/schemas/gschemas.compiled")
      FileUtils.cp(
        "#{emacs_root}/share/glib-2.0/schemas/gschemas.compiled",
        "#{Dir.home}/.local/share/glib-2.0/schemas/"
      )
      FileUtils.cp(
        "#{emacs_root}/share/glib-2.0/schemas/org.gnu.emacs.defaults.gschema.xml",
        "#{Dir.home}/.local/share/glib-2.0/schemas/"
      )
    end

    # Copy icons to user directory
    icon_sizes = ["16x16", "24x24", "32x32", "48x48", "128x128", "scalable"]
    icon_sizes.each do |size|
      src_icon = "#{emacs_root}/share/icons/hicolor/#{size}/apps/emacs.png"
      src_icon = "#{emacs_root}/share/icons/hicolor/#{size}/apps/emacs.svg" if size == "scalable"

      if File.exist?(src_icon)
        FileUtils.mkdir_p "#{Dir.home}/.local/share/icons/hicolor/#{size}/apps"
        FileUtils.cp(src_icon, "#{Dir.home}/.local/share/icons/hicolor/#{size}/apps/")
      end
    end

    # Update icon cache if available
    system "gtk-update-icon-cache", "#{Dir.home}/.local/share/icons/hicolor", "-f", "-t" if system("which gtk-update-icon-cache > /dev/null 2>&1")

    # Install desktop files with corrected Exec paths
    desktop_files = ["emacs", "emacsclient", "emacs-mail", "emacsclient-mail"]
    desktop_files.each do |desktop_name|
      src_desktop = "#{emacs_root}/share/applications/#{desktop_name}.desktop"
      next unless File.exist?(src_desktop)

      desktop_content = File.read(src_desktop)
      # Fix Exec paths to use homebrew bin directory
      desktop_content.gsub!(%r{Exec=emacs}, "Exec=#{HOMEBREW_PREFIX}/bin/emacs")
      desktop_content.gsub!(%r{Exec=/usr/local/bin/emacs}, "Exec=#{HOMEBREW_PREFIX}/bin/emacs")
      desktop_content.gsub!(%r{Exec=/usr/local/bin/emacsclient}, "Exec=#{HOMEBREW_PREFIX}/bin/emacsclient")
      desktop_content.gsub!(%r{Exec=emacsclient}, "Exec=#{HOMEBREW_PREFIX}/bin/emacsclient")

      File.write("#{Dir.home}/.local/share/applications/#{desktop_name}.desktop", desktop_content)
    end

    # Update desktop database if available
    system "update-desktop-database", "#{Dir.home}/.local/share/applications" if system("which update-desktop-database > /dev/null 2>&1")
  end

  uninstall_postflight do
    # Clean up desktop files
    ["emacs", "emacsclient", "emacs-mail", "emacsclient-mail"].each do |desktop_name|
      FileUtils.rm_f("#{Dir.home}/.local/share/applications/#{desktop_name}.desktop")
    end

    # Clean up icons
    icon_sizes = ["16x16", "24x24", "32x32", "48x48", "128x128", "scalable"]
    icon_sizes.each do |size|
      icon_ext = size == "scalable" ? "svg" : "png"
      FileUtils.rm_f("#{Dir.home}/.local/share/icons/hicolor/#{size}/apps/emacs.#{icon_ext}")
    end

    # Clean up gschemas
    FileUtils.rm_f("#{Dir.home}/.local/share/glib-2.0/schemas/gschemas.compiled")
    FileUtils.rm_f("#{Dir.home}/.local/share/glib-2.0/schemas/org.gnu.emacs.defaults.gschema.xml")

    # Update caches
    system "gtk-update-icon-cache", "#{Dir.home}/.local/share/icons/hicolor", "-f", "-t" if system("which gtk-update-icon-cache > /dev/null 2>&1")
    system "update-desktop-database", "#{Dir.home}/.local/share/applications" if system("which update-desktop-database > /dev/null 2>&1")
  end
end
