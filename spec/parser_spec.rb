require 'spec_helper'

include Liquider
include Liquider::Spec

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
      [:TAGOPEN, '{% block'],
      [:MARKUP, ''],
      [:TAGCLOSE, '%}'],
      [:TEXT, 'foo'],
      [:ENDBLOCK, '{% endblock %}'],
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
      [:TAGOPEN, '{% tag'],
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

  it 'parses simple if statements' do
    tokens = [
      [:IF, '{% if'],
      [:IDENT, 'foo'],
      [:TAGCLOSE, '%}'],
      [:TEXT, 'asdf'],
      [:ENDIF, '{% endif %}'],
      [false, false],
    ]
    ast = Ast::DocumentNode.new([
      Ast::IfNode.new([
        [
          Ast::SymbolNode.new('foo'),
          Ast::DocumentNode.new([
            Ast::TextNode.new('asdf')
          ])
        ]
      ]),
    ])
    expect(parse(tokens)).to eq(ast)
  end

  it 'parses if-else statements' do
    tokens = [
      [:IF, '{% if'],
      [:IDENT, 'foo'],
      [:TAGCLOSE, '%}'],
      [:TEXT, 'asdf'],
      [:ELSE, '{% else %}'],
      [:MUSTACHEOPEN, '{{'],
      [:IDENT, 'bar'],
      [:MUSTACHECLOSE, '}}'],
      [:ENDIF, '{% endif %}'],
      [false, false],
    ]
    ast = Ast::DocumentNode.new([
      Ast::IfNode.new([
        [
          Ast::SymbolNode.new('foo'),
          Ast::DocumentNode.new([
            Ast::TextNode.new('asdf')
          ])
        ], [
          Ast::BooleanNode.new(true),
          Ast::DocumentNode.new([
            Ast::MustacheNode.new(Ast::SymbolNode.new('bar'))
          ])
        ]
      ]),
    ])
    expect(parse(tokens)).to eq(ast)
  end

  it 'parses if-elsif-else statements' do
    tokens = [
      [:IF, '{% if'],
      [:IDENT, 'foo'],
      [:TAGCLOSE, '%}'],
      [:TEXT, 'asdf'],
      [:ELSIF, '{% elsif'],
      [:FALSE, 'false'],
      [:TAGCLOSE, '%}'],
      [:ELSE, '{% else %}'],
      [:MUSTACHEOPEN, '{{'],
      [:IDENT, 'bar'],
      [:MUSTACHECLOSE, '}}'],
      [:ENDIF, '{% endif %}'],
      [false, false],
    ]
    ast = Ast::DocumentNode.new([
      Ast::IfNode.new([
        [
          Ast::SymbolNode.new('foo'),
          Ast::DocumentNode.new([
            Ast::TextNode.new('asdf')
          ])
        ], [
          Ast::BooleanNode.new(false),
          Ast::DocumentNode.new([])
        ], [
          Ast::BooleanNode.new(true),
          Ast::DocumentNode.new([
            Ast::MustacheNode.new(Ast::SymbolNode.new('bar'))
          ])
        ]
      ]),
    ])
    expect(parse(tokens)).to eq(ast)
  end

  it 'parses unless statements' do
    tokens = [
      [:UNLESS, '{% unless'],
      [:IDENT, 'foo'],
      [:TAGCLOSE, '%}'],
      [:TEXT, 'asdf'],
      [:ENDUNLESS, '{% endunless %}'],
      [false, false],
    ]
    ast = Ast::DocumentNode.new([
      Ast::IfNode.new([
        [
          Ast::NegationNode.new(Ast::SymbolNode.new('foo')),
          Ast::DocumentNode.new([
            Ast::TextNode.new('asdf')
          ])
        ]
      ]),
    ])
    expect(parse(tokens)).to eq(ast)
  end

  private

  def parse(tokens)
    Parser.new(TAGS, tokens).parse
  end
end
