require 'test_helper'

class TestScanner < LiquiderTestCase
  def test_detects_single_tokens
    scanner = Liquider::Scanner.new('asdf')
    token = scanner.consume_first_of(Liquider::Tokens::Ident)
    assert_instance_of Liquider::Tokens::Ident, token
    assert_equal 'asdf', token.text
  end

  def test_consumes_single_tokens
    scanner = Liquider::Scanner.new('asdf')
    refute_nil scanner.consume_first_of(Liquider::Tokens::Ident)
    assert_nil scanner.consume_first_of(Liquider::Tokens::Ident)
  end

  def test_consumes_first_of
    scanner = Liquider::Scanner.new('{{')
    assert_instance_of(
      Liquider::Tokens::MustacheOpen,
      scanner.consume_first_of(Liquider::Tokens::Ident, Liquider::Tokens::MustacheOpen)
    )
  end

  def test_can_skip_white_space
    scanner = Liquider::Scanner.new('   asdf')
    assert_nil scanner.consume_first_of(Liquider::Tokens::Ident)
    scanner.consume_whitespace
    refute_nil scanner.consume_first_of(Liquider::Tokens::Ident)
  end

  def test_reports_column
    scanner = Liquider::Scanner.new("a b000\n c00 d")
    assert_token_starts_on_column 1, scanner.consume_first_of(Liquider::Tokens::Ident)
    scanner.consume_whitespace
    assert_token_starts_on_column 3, scanner.consume_first_of(Liquider::Tokens::Ident)
    scanner.consume_whitespace
    assert_token_starts_on_column 2, scanner.consume_first_of(Liquider::Tokens::Ident)
    scanner.consume_whitespace
    assert_token_starts_on_column 6, scanner.consume_first_of(Liquider::Tokens::Ident)
  end

  private

  def assert_token_starts_on_column(expected, token)
    assert_equal expected, token.column, "Expected #{token} to start on column #{expected}"
  end
end
