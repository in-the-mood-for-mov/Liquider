class Liquider::Scanner
  extend Forwardable
  include Enumerable

  END_OF_TOP_LEVEL_TEXT = Regexp.union(
    Liquider::Tokens::Eos.pattern,
    Liquider::Tokens::MustacheOpen.pattern,
    Liquider::Tokens::TagOpen.pattern,
  )

  class << self
    def from_string(s)
      Scanner.new(TextStream.new(s))
    end
  end

  def initialize(string_scanner)
    @string_scanner = string_scanner
  end

  def each
    while !eos?
      text = string_scanner.scan_until(END_OF_TOP_LEVEL_TEXT)

      yield Tokens::Text.new(text, 0, 0).to_racc unless text.nil? || text.empty?
      return if eos?

      longest_match = Liquider::Tokens::LEXEMES.map { |lexeme|
        lexeme.check(string_scanner)
      }.max { |match|
        match.text.length
      }

      unless longest_match.nil?
        string_scanner.pos += longest_match.text.length
        yield longest_match.to_racc unless longest_match.ignore?
      end
    end
  end

  private

  attr_reader :string_scanner, :lexemes

  def_delegators :string_scanner, :eos?
end
