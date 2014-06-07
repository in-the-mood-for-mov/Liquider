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
  it 'can scan plain text' do
    expect('asdf').to be_scanned_as([
      [:TEXT, 'asdf'],
      [false, false]
    ])
  end

  it 'can scan expressions' do
    expect('{{ foo + 5 }}').to be_scanned_as([
      [:MUSTACHEOPEN, '{{'],
      [:IDENT, 'foo'],
      [:PLUS, '+'],
      [:NUMBER, '5'],
      [:MUSTACHECLOSE, '}}'],
      [false, false],
    ])
  end

  it 'can scan tags' do
    expect('{% foo asdf + 3 %}').to be_scanned_as([
      [:TAGOPEN, '{%'],
      [:IDENT, 'foo'],
      [:MARKUP, ' asdf + 3 '],
      [:TAGCLOSE, '%}'],
      [false, false],
    ])
  end
end
