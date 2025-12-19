# Homebrew Formula for Luma Template Engine
# To install:
#   brew install luma.rb
# Or add to a tap:
#   brew tap santosr2/luma
#   brew install luma

class Luma < Formula
  desc "Fast, clean templating language with full Jinja2 compatibility"
  homepage "https://github.com/santosr2/luma"
  url "https://github.com/santosr2/luma/archive/v1.0.0.tar.gz"
  sha256 ""  # Will be calculated after creating the release tarball
  license "MIT"
  head "https://github.com/santosr2/luma.git", branch: "main"

  depends_on "luajit"
  depends_on "luarocks"

  def install
    # Install via LuaRocks
    system "luarocks", "make", "--tree=#{prefix}", "luma-#{version}-1.rockspec"

    # Install CLI binary
    bin.install "bin/luma"

    # Install documentation
    doc.install "README.md"
    doc.install "docs"

    # Install examples
    (share/"luma/examples").install Dir["examples/*"]

    # Install man pages (if available)
    # man1.install "man/luma.1" if File.exist?("man/luma.1")
  end

  test do
    # Test basic rendering
    output = shell_output("#{bin}/luma render - --data '{\"name\": \"World\"}'", 0) do |stdin|
      stdin.write("Hello, $name!")
    end
    assert_match "Hello, World!", output

    # Test version
    assert_match version.to_s, shell_output("#{bin}/luma --version")

    # Test Lua API
    (testpath/"test.lua").write <<~LUA
      local luma = require("luma")
      local result = luma.render("Hello, $name!", {name = "Test"})
      assert(result == "Hello, Test!")
      print("OK")
    LUA
    system "luajit", "test.lua"
  end
end
