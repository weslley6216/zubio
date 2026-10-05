require "rails_helper"

RSpec.describe "Comment discipline" do
  let(:magic_comment) { "# frozen_string_literal: true" }
  let(:ruby_comment) { /\A[ \t]*\#(?=\s|\z)|\A=(?:begin|end)\b/ }
  let(:javascript_comment) { %r{\A[ \t]*//} }

  it "leaves no comment line in app or spec" do
    ruby_files = Dir[Rails.root.join("{app,spec}/**/*.rb")]
    javascript_files = Dir[Rails.root.join("{app,spec}/**/*.js")]

    offenders = ruby_files.select { |path| File.readlines(path, chomp: true).reject { |line| line.strip == magic_comment }.grep(ruby_comment).any? } +
      javascript_files.select { |path| File.readlines(path, chomp: true).grep(javascript_comment).any? }

    expect(offenders.map { |path| Pathname.new(path).relative_path_from(Rails.root).to_s }).to be_empty
  end

  it "flags every shape of comment a Ruby file can carry" do
    expect([ "# probe", "  # probe", "=begin probe", "=end probe" ].grep(ruby_comment).size).to eq(4)
  end

  it "flags every shape of comment a JavaScript file can carry" do
    expect([ "// probe", "  // probe" ].grep(javascript_comment).size).to eq(2)
  end

  it "keeps a line of code out of the count" do
    expect([ %(greeting = "hello") ].grep(ruby_comment)).to be_empty
  end

  it "recognizes the magic comment as a comment, which the scan of the codebase leaves out by name" do
    expect([ magic_comment ].grep(ruby_comment)).to eq([ magic_comment ])
  end

  it "keeps interpolation at the start of a line out of the count" do
    expect([ '  #{new_owner_session_url(host: tenant.canonical_host)}' ].grep(ruby_comment)).to be_empty
  end

  it "keeps a hex color literal at the start of a line out of the count" do
    expect([ "    #4F46E5 #7C3AED #1E60C4" ].grep(ruby_comment)).to be_empty
  end

  it "still flags a bare hash on a line of its own" do
    expect([ "  #" ].grep(ruby_comment).size).to eq(1)
  end

  it "keeps a JavaScript private method out of the count" do
    expect([ "  #remember(theme) {" ].grep(javascript_comment)).to be_empty
  end
end
