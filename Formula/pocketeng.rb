class Pocketeng < Formula
  desc "Claude Code on your cloud, from anywhere"
  homepage "https://github.com/vaibs-d/pocketengineer"
  url "https://github.com/vaibs-d/pocketengineer/archive/refs/heads/main.tar.gz"
  version "1.2.0"
  license "MIT"

  def install
    bin.install "pocketeng"
  end

  test do
    assert_match "pocketeng", shell_output("#{bin}/pocketeng --version")
  end
end
