class Liquider::Scanner
  include Enumerable
  include Liquider::Tokens

  def initialize(text_stream, mode: :text)
    @text_stream = text_stream
    @mode = mode
  end

  def each(&block)
    loop do
      case @mode
      when :text then scan_text(&block)
      when :enter_liquid then scan_enter_liquid(&block)
      when :liquid then scan_liquid(&block)
      when :markup then scan_markup(&block)
      when :eos then return
      end
    end
  end

  private

  attr_reader :text_stream

  def eat_whitespace
    scan_tokens([WhiteSpace]) { |token| }
  end

  TEXT_TOKENS = [
    TextToken,
    EosToken,
  ].freeze

  def scan_text(&block)
    scan_tokens(TEXT_TOKENS, &block)
  end

  ENTER_LIQUID_TOKENS = [
    RawTextToken,
    MustacheOpenToken,
    IfToken,
    ElsifToken,
    ElseToken,
    EndIfToken,
    UnlessToken,
    EndUnlessToken,
    CaseToken,
    WhenToken,
    EndCaseToken,
    TagOpenToken,
    EndBlockToken,
    EosToken
  ].freeze

  def scan_enter_liquid(&block)
    scan_tokens(ENTER_LIQUID_TOKENS, &block)
  end

  LIQUID_TOKENS = [
    RawTextToken,
    IdentToken,
    NumberToken,
    StringToken,
    TrueToken,
    FalseToken,
    PipeToken,
    DotToken,
    DoubleDotToken,
    ColonToken,
    CommaToken,
    TimesToken,
    DivToken,
    PlusToken,
    MinusToken,
    EqToken,
    NeToken,
    LtToken,
    LeToken,
    GtToken,
    GeToken,
    ContainsToken,
    ParenOpenToken,
    ParenCloseToken,
    MustacheCloseToken,
    TagCloseToken,
    EosToken,
  ].freeze

  def scan_liquid(&block)
    eat_whitespace
    scan_tokens(LIQUID_TOKENS, &block)
  end

  def scan_markup(&block)
    scan_tokens([MarkupToken], &block)
  end

  def scan_tokens(tokens)
    longest_match = tokens.map { |token_type|
      match = text_stream.check(token_type.pattern)
      next NullToken.new('', text_stream.source_info) if match.nil?
      token_type.new(match.to_s, text_stream.source_info)
    }.max_by { |match|
      match.weight
    }

    longest_match.raise_on_error(tokens, text_stream)
    text_stream.pos += longest_match.text.length
    @mode = longest_match.next_mode(@mode)
    yield longest_match.to_racc unless longest_match.ignore?
  end

  def raise_token_not_found(tokens)
  end

end
