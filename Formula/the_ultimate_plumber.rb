class TheUltimatePlumber < Formula
  desc "Ultimate Plumber is a tool for writing Linux pipes with instant live preview"
  homepage "https://github.com/akavel/up#readme"
  url "https://github.com/akavel/up/archive/v0.3.1.tar.gz"
  sha256 "4e423e2a97a9d4a45a89ab37a6ff6ea826d2849eae0ef8258346900189afc643"

  depends_on "go" => :build

  def install
    dir = buildpath/"src/github.com/akavel/up"
    dir.install buildpath.children
    cd dir do
      ENV["GOPATH"] = buildpath
      ENV["GO111MODULE"] = "on"
      system "go", "build", "-o", bin/"up", "up.go"
      prefix.install_metafiles
    end
  end

  test do
    expected_help_message = <<~EOS
      Usage of up:
            --debug                  debug mode
        -o, --output-script file     save the command to specified file if Ctrl-X is pressed (default: up<N>.sh)
            --unsafe-full-throttle   enable mode in which command is executed immediately after any change
      pflag: help requested
    EOS
    assert_equal expected_help_message, shell_output("#{bin}/up --help")
  # TODO probably need to do something with expect, in order to test
  # interactivity
  end
end
