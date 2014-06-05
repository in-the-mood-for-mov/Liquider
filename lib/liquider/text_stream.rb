require 'strscan'

class Liquider::TextStream
  extend Forwardable

  def initialize(source)
    @scanner = StringScanner.new(source)
    @line = @column = 1
  end

  def scan(pattern)
    line, column = @line, @column
    matched = @scanner.scan(pattern)
    adjust_position matched
    [matched, line, column]
  end

  def_delegators :@scanner, :eos?

  private

  def adjust_position(text)
    return if text.nil?

    lines = text.split("\n")
    case lines.count
    when 1 then @column += lines.first.size
    else
      @column = lines.last.size + 1
      @line += lines.count
    end
  end
end
