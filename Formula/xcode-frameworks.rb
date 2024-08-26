class XcodeFrameworks < Formula
  desc "A CLI tool for managing frameworks and xcframeworks in an Xcode project."
  homepage "https://github.com/yourusername/xcode-frameworks"
  url "https://github.com/yourusername/xcode-frameworks/archive/refs/tags/0.1.0.tar.gz"
  sha256 ""
  license "MIT"

  depends_on "swift" => :build

  def install
    system "swift", "build", "-c", "release"
    bin.install ".build/release/xcode-frameworks"
  end

  test do
    system "#{bin}/xcode-frameworks", "--help"
  end
end