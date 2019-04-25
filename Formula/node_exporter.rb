class NodeExporter < Formula
  desc "Prometheus exporter for machine metrics"
  homepage "https://prometheus.io/"
  url "https://github.com/prometheus/node_exporter/archive/v0.17.0.tar.gz"
  sha256 "763b588b9282a8aa497286f8ab1aab61d085bdd2d258cf3457f23c60752c9a27"

  bottle do
    cellar :any_skip_relocation
    sha256 "18aec98484b6171e130b362cb4fdf061ae556889b5a4d0f5e54590bed772d40f" => :mojave
    sha256 "73a63fee885b246f401e3bb5f2ba2ef151a0d445d2c5be3480eb5ad7e34c5150" => :high_sierra
    sha256 "a2f81f31c72150cff3ce0442ae63e783b4c8d9ea6b04cce353caed36f373c464" => :sierra
    sha256 "43917856258a8a777b2632921070b002853b266438495320ca20d5eda6a95809" => :el_capitan
  end

  depends_on "go" => :build

  resource "promu" do
    # check and update upon next release
    # (matches <https://github.com/prometheus/node_exporter/blob/v0.17.0/Makefile.common#L68-L69>)
    url "https://github.com/prometheus/promu/releases/download/v0.2.0/promu-0.2.0.darwin-amd64.tar.gz"
    sha256 "6372caea7d8e7c0f208f6c040e2bfb462c72c9f7b2f6c13b7992d7caa5fbcf75"
  end

  # Fix checksum mismatch of `soundcloud/go-runit@v0.0.0-20150630195641-06ad41a06c4a`.
  patch do
    url "https://github.com/prometheus/node_exporter/commit/97dab59e18c575d1384a9afd54e9f30473f34322.patch?full_index=1"
    sha256 "a581e7304823fecc0a5dd71ce27ba66add9665bad702ced837b63f1eda4c5082"
  end

  def install
    system "make", "test"

    # Trick build into using our checksummed `promu`.
    resource("promu").stage do
      gopath = `go env GOPATH`.chomp
      Pathname.new("#{gopath}/bin").install "./promu"
    end

    system "make", "build", "PREFIX=#{bin}"
    prefix.install_metafiles
  end

  def caveats; <<~EOS
    When used with `brew services`, node_exporter's configuration is stored as command line flags in
      #{etc}/node_exporter.args

    Example configuration:
      echo --web.listen-address :9101 > #{etc}/node_exporter.args

    For the full list of options, execute
      node_exporter -h
  EOS
  end

  plist_options :manual => "node_exporter"

  def plist; <<~EOS
    <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>sh</string>
          <string>-c</string>
          <string>#{opt_bin}/node_exporter $(&lt; #{etc}/node_exporter.args)</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <false/>
        <key>StandardErrorPath</key>
        <string>#{var}/log/node_exporter.err.log</string>
        <key>StandardOutPath</key>
        <string>#{var}/log/node_exporter.log</string>
      </dict>
    </plist>
  EOS
  end

  test do
    output = shell_output("#{bin}/node_exporter --version 2>&1")
    assert_match version.to_s, output
    begin
      pid = fork { exec bin/"node_exporter" }
      sleep 2
      assert_match "# HELP", shell_output("curl -s localhost:9100/metrics")
    ensure
      Process.kill("SIGINT", pid)
      Process.wait(pid)
    end
  end
end
