require 'spec_helper'

include Liquider

class TestBlock
  class << self
    def block?
      true
    end

    def parse_markup(source)
      :markup
    end
  end
end

class TestTag
  class << self
    def block?
      false
    end

    def parse_markup(source)
      :markup
    end
  end
end

TAGS = {
  'block' => TestBlock,
  'tag' => TestTag,
}

describe Parser do
  it 'parses symbols' do
    tokens = [
      [:GOTOEXPRESSION, ''],
      [:IDENT, 'foo'],
      [false, false]
    ]
    ast = Liquider::Ast::SymbolNode.new('foo')
    expect(parse tokens).to eq(ast)
  end

  it 'parses expressions with various binary operators' do
    tokens = [
      [:GOTOEXPRESSION, ''],
      [:IDENT, 'foo'],
      [:PLUS, '+'],
      [:STRING, 'bar'],
      [:TIMES, '*'],
      [:IDENT, 'baz'],
      [:LT, '<'],
      [:NUMBER, 40],
      [false, false]
    ]
    ast = Liquider::Ast::BinOpNode.new(
      :<,
      Liquider::Ast::BinOpNode.new(
        :+,
        Liquider::Ast::SymbolNode.new('foo'),
        Liquider::Ast::BinOpNode.new(
          :*,
          Liquider::Ast::StringNode.new('bar'),
          Liquider::Ast::SymbolNode.new('baz'),
        ),
      ),
      Liquider::Ast::NumberNode.new(40),
    )
    expect(parse tokens).to eq(ast)
  end

  it 'can parse argument list' do
    tokens = [
      [:GOTOARGLIST, ''],
      [:IDENT, 'foo'],
      [:COMMA, ','],
      [:STRING, 'bar'],
      [:COMMA, ','],
      [:IDENT, 'baz'],
      [:COLON, ':'],
      [:NUMBER, '25'],
      [:PLUS, '+'],
      [:NUMBER, '36'],
      [:COMMA, ','],
      [:IDENT, 'quux'],
      [:COLON, ':'],
      [:IDENT, 'asdf'],
      [false, false],
    ]
    ast = Ast::ArgListNode.new(
      [
        Ast::SymbolNode.new('foo'),
        Ast::StringNode.new('bar'),
      ], [
        Ast::OptionPairNode.new(
          'baz',
          Ast::BinOpNode.new(
            :+,
            Ast::NumberNode.new('25'),
            Ast::NumberNode.new('36')
          )
        ),
        Ast::OptionPairNode.new(
          'quux',
          Ast::SymbolNode.new('asdf'),
        )
      ]
    )
    expect(parse tokens).to eq(ast)
  end

  it 'can parse blocks' do
    tokens = [
      [:TAGOPEN, '{%'],
      [:IDENT, 'block'],
      [:MARKUP, ''],
      [:TAGCLOSE, '%}'],
      [:TEXT, 'foo'],
      [:BLOCKTAIL, '{% endblock %}'],
      [false, false],
    ]
    ast = Ast::DocumentNode.new([
      Ast::TagNode.new(
        'block',
        :markup,
        Ast::DocumentNode.new([
          Ast::TextNode.new('foo')
        ])
      )
    ])
    expect(parse tokens).to eq(ast)
  end

  it 'can parse tags' do
    tokens = [
      [:TAGOPEN, '{%'],
      [:IDENT, 'tag'],
      [:MARKUP, ''],
      [:TAGCLOSE, '%}'],
      [false, false],
    ]
    ast = Ast::DocumentNode.new([
      Ast::TagNode.new('tag', :markup)
    ])
    expect(parse tokens).to eq(ast)
  end

  it 'can parse filters' do
    tokens = [
      [:GOTOEXPRESSION, ''],
      [:IDENT, "identifier"],
      [:PIPE, "|"],
      [:IDENT, "filter1"],
      [:PIPE, "|"],
      [:IDENT, "filter2"],
      [false, false]
    ]
    ast = Ast::FilterNode.new(
      "filter2",
      Ast::ArgListNode.new([
        Ast::FilterNode.new(
          "filter1",
          Ast::ArgListNode.new([
            Ast::SymbolNode.new("identifier")
          ], [])
        )], []
      )
    )
    expect(parse(tokens)).to eq(ast)
  end

  private

  def parse(tokens)
    Parser.new(TAGS, tokens).parse
  end
end
