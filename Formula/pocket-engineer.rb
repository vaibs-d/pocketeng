class PocketEngineer < Formula
  desc "Claude Code on your cloud, from anywhere"
  homepage "https://github.com/vaibs-d/pocketengineer"
  url "https://github.com/vaibs-d/pocketengineer/archive/refs/heads/main.tar.gz"
  version "1.1.0"
  license "MIT"

  def install
    bin.install "pocket-engineer"
  end

  test do
    assert_match "pocket-engineer", shell_output("#{bin}/pocket-engineer --version")
  end
end
