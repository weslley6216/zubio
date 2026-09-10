require "rails_helper"

RSpec.describe "Comment discipline" do
  MAGIC_COMMENT = "# frozen_string_literal: true".freeze
  RUBY_COMMENT = /\A[ \t]*\#(?!\{)|\A=(?:begin|end)\b/
  JAVASCRIPT_COMMENT = %r{\A[ \t]*//}

  def comment_pattern(path)
    File.extname(path) == ".js" ? JAVASCRIPT_COMMENT : RUBY_COMMENT
  end

  def commented_lines(source, path = "probe.rb")
    source.lines.map(&:chomp).reject { |line| line.strip == MAGIC_COMMENT }.grep(comment_pattern(path))
  end

  it "leaves no comment line in app or spec" do
    offenders = Dir[Rails.root.join("{app,spec}/**/*.{rb,js}")].select do |path|
      commented_lines(File.read(path), path).any?
    end

    expect(offenders).to be_empty, "Files carrying comments: #{offenders.map { |path| Pathname.new(path).relative_path_from(Rails.root) }.join(', ')}"
  end

  it "flags every shape of comment a Ruby file can carry" do
    probe = [ "#", "  #", "=begin", "=end" ].map { |marker| "#{marker} probe" }.join("\n")

    expect(commented_lines(probe, "probe.rb").size).to eq(4)
  end

  it "flags every shape of comment a JavaScript file can carry" do
    probe = [ "//", "  //" ].map { |marker| "#{marker} probe" }.join("\n")

    expect(commented_lines(probe, "probe.js").size).to eq(2)
  end

  it "keeps the magic comment and a line of code out of the count" do
    probe = [ MAGIC_COMMENT, %(greeting = "hello") ].join("\n")

    expect(commented_lines(probe, "probe.rb")).to be_empty
  end

  it "keeps interpolation at the start of a line out of the count" do
    probe = '  #{new_owner_session_url(host: tenant.canonical_host)}'

    expect(commented_lines(probe, "probe.rb")).to be_empty
  end

  it "keeps a JavaScript private method out of the count" do
    probe = "  #remember(theme) {"

    expect(commented_lines(probe, "probe.js")).to be_empty
  end
end
