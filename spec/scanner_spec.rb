require 'spec_helper'

include Liquider

RSpec::Matchers.define(:be_scanned_as) do |tokens|
  match do |source|
    [*tokens, t_eos] == Scanner.new(TextStream.new(source)).to_a
  end

  failure_message do |actual|
    actual_tokens = Scanner.new(TextStream.new(actual)).to_a
    token_table = expected.map(&:to_s).zip(actual_tokens.map(&:to_s)).map do |expected, actual|
      format("%-32s %-32s", expected, actual)
    end.join("\n")
    <<-MESSAGE.gsub(/^ */, "")
      The following source did not yield the expected tokens.
      #{actual}

      Expected                         Actual
      ------------------------------------------------------------------
      #{token_table}
    MESSAGE
  end
end

describe Scanner do
  include TokenSpecHelper

  it "can scan plain text" do
    expect("asdf").to be_scanned_as([
      t_text("asdf"),
    ])
  end

  it "can scan mustaches" do
    expect("{{ foo + 5 }}").to be_scanned_as([
      t_mustache_open,
      t_ident("foo"),
      t_plus,
      t_number(5),
      t_mustache_close,
    ])
  end

  it "scans double quoted strings" do
    expect(%({{ "asdf" }})).to be_scanned_as([
      t_mustache_open,
      t_string(%("asdf")),
      t_mustache_close,
    ])
  end

  it "scans single quoted strings" do
    expect(%({{ 'asdf' }})).to be_scanned_as([
      t_mustache_open,
      t_string(%('asdf')),
      t_mustache_close,
    ])
  end

  it "can scan keywords" do
    expect("{{ asdf:").to be_scanned_as([
      t_mustache_open,
      t_keyword(:asdf),
    ])
  end

  it "can scan mustaches surounded by text" do
    expect("<h1>{{ toto | print }}</h1>").to be_scanned_as([
      t_text("<h1>"),
      t_mustache_open,
      t_ident("toto"),
      t_pipe,
      t_ident("print"),
      t_mustache_close,
      t_text("</h1>"),
    ])
  end

  it "can scan mustaches with trailling newline" do
    expect("{{ toto }}\n").to be_scanned_as([
      t_mustache_open,
      t_ident("toto"),
      t_mustache_close,
      t_text("\n"),
    ])
  end

  it "can scan tags" do
    expect("{% foo asdf + 3 %}").to be_scanned_as([
      t_tag_open("foo"),
      t_markup(" asdf + 3 "),
      t_tag_close,
    ])
  end

  it "can scan tags surrounded by text" do
    expect("asdf{% foo asdf + 3 %}jkl;").to be_scanned_as([
      t_text("asdf"),
      t_tag_open("foo"),
      t_markup(" asdf + 3 "),
      t_tag_close,
      t_text("jkl;"),
    ])
  end

  it "gracefully handles unterminated tag" do
    expect("{% unterminat").to be_scanned_as([
      t_tag_open("unterminat"),
      t_markup(""),
    ])
  end

  it "scans blocks" do
    expect("{% billy 2 + 2 == 4 %}asdf{% endbilly %}").to be_scanned_as([
      t_tag_open("billy"),
      t_markup(" 2 + 2 == 4 "),
      t_tag_close,
      t_text("asdf"),
      t_end_block("endbilly"),
    ])
  end

  it "scans if" do
    expect("{% if a + b %}").to be_scanned_as([
      t_if,
      t_ident("a"),
      t_plus,
      t_ident("b"),
      t_tag_close,
    ])
  end

  it "scans elsif" do
    expect("{% elsif foo %}").to be_scanned_as([
      t_elsif,
      t_ident("foo"),
      t_tag_close,
    ])
  end

  it "scans else" do
    expect("{% else %}").to be_scanned_as([
      t_else,
    ])
  end

  it "scans endif" do
    expect("{% endif %}").to be_scanned_as([
      t_end_if,
    ])
  end

  it "scans unless" do
    expect("{% unless a + b %}").to be_scanned_as([
      t_unless,
      t_ident("a"),
      t_plus,
      t_ident("b"),
      t_tag_close,
    ])
  end

  it "scans endunless" do
    expect("{% endunless %}").to be_scanned_as([
      t_end_unless,
    ])
  end

  it "scans case" do
    expect("{% case x %}").to be_scanned_as([
      t_case,
      t_ident(:x),
      t_tag_close,
    ])
  end

  it "scans when" do
    expect(%({% when "hello" %})).to be_scanned_as([
      t_when,
      t_string(%("hello")),
      t_tag_close,
    ])
  end

  it "scans endcase" do
    expect("{% endcase %}").to be_scanned_as([
      t_end_case,
    ])
  end

  it "scans for" do
    expect("{% for x in foo %}").to be_scanned_as([
      t_for,
      t_ident(:x),
      t_in,
      t_ident(:foo),
      t_tag_close,
    ])
  end

  it "scans reversed for" do
    expect("{% for x in foo reversed %}").to be_scanned_as([
      t_for,
      t_ident(:x),
      t_in,
      t_ident(:foo),
      t_reversed,
      t_tag_close,
    ])
  end

  it "scans endfor" do
    expect("{% endfor %}").to be_scanned_as([
      t_end_for,
    ])
  end

  it "scans assigns" do
    expect("{% assign x = 2 + 3 %}").to be_scanned_as([
      t_assign,
      t_ident(:x),
      t_eq,
      t_number(2),
      t_plus,
      t_number(3),
      t_tag_close,
    ])
  end

  it "scans capture" do
    expect("{% capture foo %}asdf{% endcapture %}").to be_scanned_as([
      t_capture,
      t_ident(:foo),
      t_tag_close,
      t_text("asdf"),
      t_end_capture,
    ])
  end
end
