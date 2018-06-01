class Pijul < Formula
  desc "Patch-based distributed version control system, easy to use and fast"
  homepage "https://pijul.org"
  url "https://crates.io/api/v1/crates/pijul/0.10.1/download"
  sha256 "042ba7e96730dd90eab53db243ee7e6f0c93aa4123450f279c2f58ba5b7caf18"

  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  depends_on "libsodium"
  depends_on "openssl"

  def install
    system "cargo", "install", "--root=#{prefix}", "--verbose"
  end

  test do
    system bin/"pijul", "init"
    %w[haunted house].each { |f| touch testpath/f }
    system bin/"pijul", "add", "haunted", "house"
    system bin/"pijul", "record", "--all",
                                  "--message='Initial Patch'",
                                  "--author='Foo Bar <baz@example.com>'"
    assert_equal "haunted\nhouse\n", shell_output("#{bin}/pijul ls")
  end
end
