require 'strscan'

SourceInfo = Struct.new :line, :column

class Liquider::TextStream
  extend Forwardable

  def initialize(source)
    @scanner = StringScanner.new(source)
    @line = @column = 1
  end

  def scan(pattern)
    matched = @scanner.scan(pattern)
    adjust_position matched
    matched
  end

  def scan_until(pattern)
    matched = @scanner.scan_until(pattern)
    adjust_position matched
    matched
  end

  def source_info
    SourceInfo.new(@line, @column)
  end

  def_delegators :@scanner, :eos?, :check, :pos, :pos=

  private

  def adjust_position(text)
    return if text.nil? || text.empty?

    lines = text.split("\n")
    case lines.count
    when 1 then @column += lines.first.size
    else
      @column = lines.last.size + 1
      @line += lines.count
    end
  end
end
