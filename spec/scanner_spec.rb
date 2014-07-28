require 'spec_helper'

include Liquider

RSpec::Matchers.define :be_scanned_as do |tokens|
  match do |source|
    tokens == Scanner.new(TextStream.new(source)).to_a
  end

  failure_message do |actual|
    actual_tokens = Scanner.new(TextStream.new(actual)).to_a
    <<MESSAGE
The source "#{actual}" did not yield the expected tokens.
Expected\t\t\t\tActual
---------------------------------------
#{expected.map(&:to_s).zip(actual_tokens.map(&:to_s)).map { |*pair| pair.join("\t\t\t") }.join("\n")}
MESSAGE
  end
end

describe Scanner do
  include TokenSpecHelper

  it 'can scan plain text' do
    expect('asdf').to be_scanned_as([
      [:TEXT, 'asdf'],
      [false, false]
    ])
  end

  it 'can scan mustaches' do
    expect('{{ foo + 5 }}').to be_scanned_as([
      [:MUSTACHEOPEN, '{{'],
      [:IDENT, 'foo'],
      [:PLUS, '+'],
      [:NUMBER, '5'],
      [:MUSTACHECLOSE, '}}'],
      [false, false],
    ])
  end

  it "can scan keywords" do
    expect('{{ asdf:').to be_scanned_as([
      t_mustache_open,
      t_keyword(:asdf),
      t_eos,
    ])
  end

  it 'can can mustaches surounded by text' do
    expect("<h1>{{ toto | print }}</h1>").to be_scanned_as([
      [:TEXT, '<h1>'],
      [:MUSTACHEOPEN, '{{'],
      [:IDENT, 'toto'],
      [:PIPE, '|'],
      [:IDENT, 'print'],
      [:MUSTACHECLOSE, '}}'],
      [:TEXT, '</h1>'],
      [false, false],
    ])
  end

  it 'can scan mustaches with trailling newline' do
    expect("{{ toto }}\n").to be_scanned_as([
      [:MUSTACHEOPEN, '{{'],
      [:IDENT, 'toto'],
      [:MUSTACHECLOSE, '}}'],
      [:TEXT, "\n"],
      [false, false],
    ])
  end

  it 'can scan tags' do
    expect('{% foo asdf + 3 %}').to be_scanned_as([
      [:TAGOPEN, '{% foo'],
      [:MARKUP, ' asdf + 3 '],
      [:TAGCLOSE, '%}'],
      [false, false],
    ])
  end

  it 'can scan tags surrounded by text' do
    expect('asdf{% foo asdf + 3 %}jkl;').to be_scanned_as([
      [:TEXT, 'asdf'],
      [:TAGOPEN, '{% foo'],
      [:MARKUP, ' asdf + 3 '],
      [:TAGCLOSE, '%}'],
      [:TEXT, 'jkl;'],
      [false, false],
    ])
  end

  it 'gracefully handles unterminated tag' do
    expect('{% unterminat').to be_scanned_as([
      [:TAGOPEN, '{% unterminat'],
      [:MARKUP, ''],
      [false, false],
    ])
  end

  it 'scans blocks' do
    expect('{% billy 2 + 2 == 4 %}asdf{% endbilly %}').to be_scanned_as([
      [:TAGOPEN, '{% billy'],
      [:MARKUP, ' 2 + 2 == 4 '],
      [:TAGCLOSE, '%}'],
      [:TEXT, 'asdf'],
      [:ENDBLOCK, '{% endbilly %}'],
      [false, false],
    ])
  end

  it 'scans if' do
    expect('{% if a + b %}').to be_scanned_as([
      [:IF, '{% if'],
      [:IDENT, 'a'],
      [:PLUS, '+'],
      [:IDENT, 'b'],
      [:TAGCLOSE, '%}'],
      [false, false],
    ])
  end

  it 'scans elsif' do
    expect('{% elsif foo %}').to be_scanned_as([
      [:ELSIF, '{% elsif'],
      [:IDENT, 'foo'],
      [:TAGCLOSE, '%}'],
      [false, false],
    ])
  end

  it 'scans else' do
    expect('{% else %}').to be_scanned_as([
      [:ELSE, '{% else %}'],
      [false, false],
    ])
  end

  it 'scans endif' do
    expect('{% endif %}').to be_scanned_as([
      [:ENDIF, '{% endif %}'],
      [false, false],
    ])
  end

  it 'scans unless' do
    expect('{% unless a + b %}').to be_scanned_as([
      [:UNLESS, '{% unless'],
      [:IDENT, 'a'],
      [:PLUS, '+'],
      [:IDENT, 'b'],
      [:TAGCLOSE, '%}'],
      [false, false],
    ])
  end

  it 'scans endunless' do
    expect('{% endunless %}').to be_scanned_as([
      [:ENDUNLESS, '{% endunless %}'],
      [false, false],
    ])
  end

  it 'scans case' do
    expect('{% case x %}').to be_scanned_as([
      t_case,
      t_ident(:x),
      t_tag_close,
      t_eos,
    ])
  end

  it 'scans when' do
    expect('{% when x %}').to be_scanned_as([
      t_when,
      t_ident(:x),
      t_tag_close,
      t_eos,
    ])
  end

  it 'scans endcase' do
    expect('{% endcase %}').to be_scanned_as([
      t_end_case,
      t_eos,
    ])
  end

  it "scans for" do
    expect('{% for x in foo %}').to be_scanned_as([
      t_for,
      t_ident(:x),
      t_in,
      t_ident(:foo),
      t_tag_close,
      t_eos,
    ])
  end

  it "scans reversed for" do
    expect('{% for x in foo reversed %}').to be_scanned_as([
      t_for,
      t_ident(:x),
      t_in,
      t_ident(:foo),
      t_reversed,
      t_tag_close,
      t_eos,
    ])
  end

  it "scans endfor" do
    expect('{% endfor %}').to be_scanned_as([
      t_end_for,
      t_eos,
    ])
  end

  it "scans assigns" do
    expect('{% assign x = 2 + 3 %}').to be_scanned_as([
      t_assign,
      t_ident(:x),
      t_eq,
      t_number(2),
      t_plus,
      t_number(3),
      t_tag_close,
      t_eos,
    ])
  end

  it "scans capture" do
    expect('{% capture foo %}asdf{% endcapture %}').to be_scanned_as([
      t_capture,
      t_ident(:foo),
      t_tag_close,
      t_text('asdf'),
      t_end_capture,
      t_eos,
    ])
  end
end
