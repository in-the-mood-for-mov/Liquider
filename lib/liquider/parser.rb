class Liquider::Parser < Liquider::GeneratedParser
  attr_reader :tags, :scanner

  def initialize(tags, scanner)
    @tags, @scanner = tags, scanner
    @injected_tokens = []
  end

  def parse
    yyparse self, :tokens
  end

  private

  attr_reader :injected_tokens

  def inject_token(token)
    injected_tokens.unshift(token)
  end

  def tokens
    token_stream = @scanner.to_enum
    loop do
      injected_tokens.each { |token| yield token }.clear
      yield token_stream.next
    end
  end

  def tag_with_name(name)
    tag = tags[name]
    raise LiquiderSyntaxError.new(%Q<Unknown tag "#{name}".>) unless tag
    tag
  end
end
