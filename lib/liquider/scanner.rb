class Liquider::Scanner
  extend Forwardable
  include Enumerable

  END_OF_TOP_LEVEL_TEXT = Regexp.union(
    /\z/,
    Liquider::Tokens::MUSTACHE_OPEN.pattern,
    Liquider::Tokens::TAG_OPEN.pattern,
  )

  class << self
    def from_string(s, lexemes)
      Liquider::Scanner.new(Liquider::TextStream.new(s), lexemes)
    end
  end

  def initialize(string_scanner, lexemes)
    @string_scanner = string_scanner
    @lexemes = lexemes
  end

  def each
    while !eos?
      text = string_scanner.scan_until(END_OF_TOP_LEVEL_TEXT)

      yield Liquider::Tokens::Text.new(text, 0, 0).to_racc unless text.nil? || text.empty?
      return if eos?

      longest_match = lexemes.map {
        |lexeme| lexeme.check(string_scanner)
      }.max {
        |match| match.text.length
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
