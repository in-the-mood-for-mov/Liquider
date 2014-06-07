class Liquider::Scanner
  include Enumerable

  END_OF_TOP_LEVEL_TEXT = /\z|(?=\{\{)|(?=\{%)/

  def initialize(text_stream)
    @text_stream = text_stream
    @mode = :text
  end

  def each(&block)
    loop do
      case @mode
      when :text then scan_text(&block)
      when :liquid then scan_liquid(&block)
      when :markup then scan_markup(&block)
      when :tag_leader then scan_liquid(&block)
      when :tag_markup then scan_markup(&block)
      when :eos then return
      end
    end
  end

  private

  attr_reader :text_stream

  def scan_text
    source_info = text_stream.source_info
    text = text_stream.scan_until(END_OF_TOP_LEVEL_TEXT)
    yield Liquider::Tokens::Text.new(text, source_info).to_racc unless text.nil? || text.empty?
    @mode = :liquid
  end

  def scan_liquid
    longest_match = Liquider::Tokens::LEXEMES.map { |lexeme|
      lexeme.check(text_stream)
    }.max_by { |match|
      match.weight
    }

    return if longest_match.nil?

    text_stream.pos += longest_match.text.length
    @mode = longest_match.next_mode(@mode)
    yield longest_match.to_racc unless longest_match.ignore?
  end

  def scan_markup
    source_info = text_stream.source_info
    text = text_stream.scan_until(/(?=%})|\z/)
    yield Liquider::Tokens::Markup.new(text, source_info).to_racc
    @mode = :liquid
  end
end
