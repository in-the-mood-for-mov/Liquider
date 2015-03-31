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
    expect(ast.op).to eq(:<)
  end

  it 'can parse argument list' do
    tokens = [
      [:GOTOARGLIST, ''],
      [:IDENT, 'foo'],
      [:COMMA, ','],
      [:STRING, 'bar'],
      [:COMMA, ','],
      [:KEYWORD, 'baz:'],
      [:NUMBER, '25'],
      [:PLUS, '+'],
      [:NUMBER, '36'],
      [:COMMA, ','],
      [:KEYWORD, 'quux:'],
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
            Ast::NumberNode.new(36),
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
        TestBlock.new(
          :markup,
          Ast::DocumentNode.new([
            Ast::TextNode.new('foo')
          ])
        )
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
      Ast::TagNode.new(TestTag.new(:markup, Ast::DocumentNode.new([])))
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
      Ast::IfNode.new(
        Ast::SymbolNode.new('foo'),
        Ast::DocumentNode.new([
          Ast::TextNode.new('asdf')
        ]),
        Ast::NullNode.new
      ),
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
      Ast::IfNode.new(
        Ast::SymbolNode.new('foo'),
        Ast::DocumentNode.new([
          Ast::TextNode.new('asdf')
        ]),
        Ast::ElseNode.new(
          Ast::DocumentNode.new([
            Ast::MustacheNode.new(Ast::SymbolNode.new('bar'))
          ])
        )
      ),
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
      [:IDENT, 'quux'],
      [:TAGCLOSE, '%}'],
      [:ELSE, '{% else %}'],
      [:MUSTACHEOPEN, '{{'],
      [:IDENT, 'bar'],
      [:MUSTACHECLOSE, '}}'],
      [:ENDIF, '{% endif %}'],
      [false, false],
    ]
    ast = Ast::DocumentNode.new([
      Ast::IfNode.new(
        Ast::SymbolNode.new('foo'),
        Ast::DocumentNode.new([
          Ast::TextNode.new('asdf')
        ]),
        Ast::IfNode.new(
          Ast::SymbolNode.new('quux'),
          Ast::DocumentNode.new([]),
          Ast::ElseNode.new(
            Ast::DocumentNode.new([
              Ast::MustacheNode.new(Ast::SymbolNode.new('bar'))
            ])
          )
        )
      ),
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
      Ast::IfNode.new(
        Ast::NegationNode.new(Ast::SymbolNode.new('foo')),
        Ast::DocumentNode.new([
          Ast::TextNode.new('asdf')
        ]),
        Ast::NullNode.new
      ),
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

  it "parses for statements" do
    tokens = [
      t_for,
      t_ident(:x),
      t_in,
      t_ident(:foo),
      t_dot,
      t_ident(:bar),
      t_tag_close,
      t_mustache_open,
      t_ident(:x),
      t_dot,
      t_ident(:title),
      t_mustache_close,
      t_end_for,
      t_eos,
    ]
    ast = Ast::DocumentNode.new([
      Ast::ForNode.new(
        Ast::SymbolNode.new('x'),
        Ast::CallNode.new(Ast::SymbolNode.new('foo'), Ast::SymbolNode.new('bar')),
        Ast::DocumentNode.new([
          Ast::MustacheNode.new(
            Ast::CallNode.new(Ast::SymbolNode.new('x'), Ast::SymbolNode.new('title'))
          ),
        ])
      ),
    ])
    expect(parse(tokens)).to eq(ast)
  end

  it "parses reversed for statements" do
    tokens = [
      t_for,
      t_ident(:x),
      t_in,
      t_ident(:foo),
      t_reversed,
      t_tag_close,
      t_end_for,
      t_eos,
    ]
    ast = Ast::DocumentNode.new([
      Ast::ForNode.new(
        Ast::SymbolNode.new('x'),
        Ast::SymbolNode.new('foo'),
        Ast::DocumentNode.new([]),
        reversed: Ast::BooleanNode.new(true),
      )
    ])
    expect(parse(tokens)).to eq(ast)
  end

  it "parses for statements with limit" do
    tokens = [
      t_for,
      t_ident(:x),
      t_in,
      t_ident(:foo),
      t_keyword(:limit),
      t_number(10),
      t_tag_close,
      t_end_for,
      t_eos,
    ]
    ast = Ast::DocumentNode.new([
      Ast::ForNode.new(
        Ast::SymbolNode.new('x'),
        Ast::SymbolNode.new('foo'),
        Ast::DocumentNode.new([]),
        limit: Ast::NumberNode.new(10),
      )
    ])
    expect(parse(tokens)).to eq(ast)
  end

  it "parses for statements with offset" do
    tokens = [
      t_for,
      t_ident(:x),
      t_in,
      t_ident(:foo),
      t_keyword(:offset),
      t_number(10),
      t_tag_close,
      t_end_for,
      t_eos,
    ]
    ast = Ast::DocumentNode.new([
      Ast::ForNode.new(
        Ast::SymbolNode.new('x'),
        Ast::SymbolNode.new('foo'),
        Ast::DocumentNode.new([]),
        offset: Ast::NumberNode.new(10),
      )
    ])
    expect(parse(tokens)).to eq(ast)
  end

  it "parses for stements with everything" do
    tokens = [
      t_for,
      t_ident(:x),
      t_in,
      t_ident(:foo),
      t_keyword(:offset),
      t_number(10),
      t_reversed,
      t_comma,
      t_keyword(:limit),
      t_ident(:bar),
      t_plus,
      t_number(10),
      t_tag_close,
      t_end_for,
      t_eos,
    ]
    ast = Ast::DocumentNode.new([
      Ast::ForNode.new(
        Ast::SymbolNode.new('x'),
        Ast::SymbolNode.new('foo'),
        Ast::DocumentNode.new([]),
        offset: Ast::NumberNode.new(10),
        limit: Ast::BinOpNode.new(:+, Ast::SymbolNode.new(:bar), Ast::NumberNode.new(10)),
        reversed: Ast::BooleanNode.new(true),
      )
    ])
    expect(parse(tokens)).to eq(ast)
  end

  it "doesn't parse for statements with redundent reverse clause" do
    tokens = [
      t_for,
      t_ident(:x),
      t_in,
      t_ident(:foo),
      t_reversed,
      t_reversed,
      t_tag_close,
      t_end_for,
      t_eos,
    ]
    expect { parse(tokens) }.to raise_error(LiquiderSyntaxError, "'reversed' was specified multiple times on 'for' tag.")
  end

  it "parses assign statements" do
    tokens = [
      t_assign,
      t_ident(:x),
      t_eq,
      t_number(2),
      t_plus,
      t_number(3),
      t_tag_close,
      t_eos,
    ]
    ast = Ast::DocumentNode.new([
      Ast::AssignNode.new(
        Ast::SymbolNode.new('x'),
        Ast::BinOpNode.new(
          :+,
          Ast::NumberNode.new(2),
          Ast::NumberNode.new(3),
        )
      ),
    ])
    expect(parse(tokens)).to eq(ast)
  end

  it "parses capture statements" do
    tokens = [
      t_capture,
      t_ident(:foo),
      t_tag_close,
      t_text('asdf'),
      t_end_capture,
      t_eos,
    ]
    ast = Ast::DocumentNode.new([
      Ast::CaptureNode.new(
        Ast::SymbolNode.new('foo'),
        Ast::DocumentNode.new([
          Ast::TextNode.new('asdf'),
        ])
      )
    ])
    expect(parse(tokens)).to eq(ast)
  end

  private

  def parse(tokens)
    Liquider::Parser.new(TAGS, tokens).parse
  end
end
