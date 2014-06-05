class Liquider::Scanner
  extend Forwardable

  class << self
    def from_string(s)
      Liquider::Scanner.new(Liquider::TextStream.new(s))
    end
  end

  def initialize(text_stream)
    @text_stream = text_stream
  end

  def consume_whitespace
    @text_stream.scan(%r<\s*>)
  end

  def consume_first_of(*token_classes)
    return if eos?
    token_classes.each do |token_class|
      text, line, column = @text_stream.scan(token_class.pattern)
      next unless text
      return token_class.new(text, line, column)
    end
    nil
  end

  def_delegators :@text_stream, :eos?
end

class Liquider::BlockScanner < Liquider::Scanner
  def intialize(block_name, text_stream)
    super(text_stream)
    @block_name = block_name
  end

  def eos?
    if @eos.nil?
      raise LiquiderSyntaxError.new(%Q(Expected "{% end#{@block_name} }%", but reached <EOF>.)) if super
      @eos = @text_stream.scan(%r<{%\s*end#{@block_name}\s*%}>)
    end
    @eos
  end
end
