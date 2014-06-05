require 'test_helper'

class TestGeneratedParser < LiquiderTestCase
  def test_symbol
    parser = make_parser(
      [:MUSTACHEOPEN, '{%'],
      [:IDENT, 'foo'],
      [:MUSTACHECLOSE, '%}'],
    )
    ast = Liquider::Ast::Document.new([
      Liquider::Ast::Mustache.new(
        Liquider::Ast::Symbol.new('foo')
      )
    ])
    assert_equal ast, parser.do_parse
  end

  def test_operator_precedence
    parser = make_parser(
      [:MUSTACHEOPEN, '{%'],
      [:IDENT, 'foo'],
      [:PLUS, '+'],
      [:STRING, 'bar'],
      [:TIMES, '*'],
      [:IDENT, 'baz'],
      [:LT, '<'],
      [:NUMBER, 40],
      [:MUSTACHECLOSE, '%}'],
    )
    ast = Liquider::Ast::Document.new([
      Liquider::Ast::Mustache.new(
        Liquider::Ast::BinOp.new(
          Liquider::Ast::BinOp.new(
            Liquider::Ast::Symbol.new('foo'),
            Liquider::Ast::BinOp.new(
              Liquider::Ast::Literal.new('bar'),
              Liquider::Ast::Symbol.new('baz'),
              :*,
            ),
            :+,
          ),
          Liquider::Ast::Literal.new(40),
          :<,
        ),
      ),
    ])
    assert_equal ast, parser.do_parse
  end

  private

  def make_parser(*token_stream)
    parser = Liquider::GeneratedParser.new
    parser.singleton_class.send(:define_method, :next_token) do
      token_stream.shift
    end
    parser
  end
end
