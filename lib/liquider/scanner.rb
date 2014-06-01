class Liquider::Scanner
  def initialize(source)
    @source = source
    @line = @column = 1
  end

  def consume_whitespace
    @source =~ %r<\A\s*>
    consume $&
  end

  def consume_first_of(*token_classes)
    token_classes.each do |token_class|
      next unless @source =~ token_class.pattern
      text = $&
      token = token_class.new(text, @line, @column)
      consume text
      return token
    end
    nil
  end

  def eof?
    return @source.empty?
  end

  private

  def consume(text)
    return unless text
    return if text.empty?

    @source.slice!(0, text.size)

    lines = text.split("\n")
    case lines.count
    when 1 then @column += lines.first.size
    else
      @column = lines.last.size + 1
      @line += lines.count
    end
    nil
  end
end
