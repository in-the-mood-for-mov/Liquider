require 'spec_helper'

describe Liquider::Parser do
  include TokenSpecHelper

  it 'parses symbols' do
    tokens = [
      [:GOTOEXPRESSION, ''],
      [:IDENT, 'foo'],
      [false, false]
    ]
    ast = Ast::SymbolNode.new('foo')
    expect(parse(tokens)).to eq(ast)
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
    ast = Ast::BinOpNode.new(
      :<,
      Ast::BinOpNode.new(
        :+,
        Ast::SymbolNode.new('foo'),
        Ast::BinOpNode.new(
          :*,
          Ast::StringNode.new('bar'),
          Ast::SymbolNode.new('baz'),
        ),
      ),
      Ast::NumberNode.new(40),
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
            Ast::NumberNode.new(25),
            Ast::NumberNode.new(36)
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
      Ast::TagNode.new('tag', :markup, Ast::DocumentNode.new([]))
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

  it 'does not parses empty case statements' do
    tokens = [
      [:CASE, '{% case'],
      [:IDENT, 'x'],
      [:TAGCLOSE, '%}'],
      [:ENDCASE, '{% endcase %}'],
      [false, false],
    ]
    expect { parse(tokens) }.to raise_error(Racc::ParseError)
  end

  it 'parses case statments with single branch' do
    tokens = [
      t_case,
      t_ident(:x),
      t_tag_close,
      t_when,
      t_number(0),
      t_tag_close,
      t_text('foo'),
      t_end_case,
      t_eos,
    ]
    ast = Ast::DocumentNode.new([
      Ast::CaseNode.new(
        Ast::SymbolNode.new('x'),
        [
          Ast::WhenNode.new(
            Ast::NumberNode.new(0),
            Ast::DocumentNode.new([Ast::TextNode.new('foo')])
          ),
        ]
      )
    ])
    expect(parse(tokens)).to eq(ast)
  end

  it 'parses case statments with single branch' do
    tokens = [
      t_case,
      t_ident(:x),
      t_tag_close,
      t_when,
      t_number(0),
      t_tag_close,
      t_text('foo'),
      t_when,
      t_number(1),
      t_tag_close,
      t_text('bar'),
      t_when,
      t_number(2),
      t_tag_close,
      t_text('quux'),
      t_end_case,
      t_eos,
    ]
    ast = Ast::DocumentNode.new([
      Ast::CaseNode.new(
        Ast::SymbolNode.new('x'),
        [
          Ast::WhenNode.new(
            Ast::NumberNode.new(0),
            Ast::DocumentNode.new([Ast::TextNode.new('foo')])
          ),
          Ast::WhenNode.new(
            Ast::NumberNode.new(1),
            Ast::DocumentNode.new([Ast::TextNode.new('bar')])
          ),
          Ast::WhenNode.new(
            Ast::NumberNode.new(2),
            Ast::DocumentNode.new([Ast::TextNode.new('quux')])
          ),
        ]
      )
    ])
    expect(parse(tokens)).to eq(ast)
  end

  it 'parses case statments with else branch' do
    tokens = [
      t_case,
      t_ident(:x),
      t_tag_close,
      t_when,
      t_number(0),
      t_tag_close,
      t_text('foo'),
      t_when,
      t_number(1),
      t_tag_close,
      t_text('bar'),
      t_else,
      t_tag_close,
      t_text('quux'),
      t_end_case,
      t_eos,
    ]
    ast = Ast::DocumentNode.new([
      Ast::CaseNode.new(
        Ast::SymbolNode.new('x'),
        [
          Ast::WhenNode.new(
            Ast::NumberNode.new(0),
            Ast::DocumentNode.new([Ast::TextNode.new('foo')])
          ),
          Ast::WhenNode.new(
            Ast::NumberNode.new(1),
            Ast::DocumentNode.new([Ast::TextNode.new('bar')])
          ),
          Ast::CaseElseNode.new(
            Ast::DocumentNode.new([Ast::TextNode.new('quux')])
          ),
        ]
      )
    ])
    expect(parse(tokens)).to eq(ast)
  end

  private

  def parse(tokens)
    Liquider::Parser.new(TAGS, tokens).parse
  end
end
