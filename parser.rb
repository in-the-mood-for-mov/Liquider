module Liquider
  BLOCK_NAMES = [
    'if',
    'for',
    'form',
    'capture'
  ]

  TAG_NAMES = [
    'cycle',
    'assign',
  ]
end

class Liquider::Parser
  def initialize(token_stream)
    @token_stream = token_stream
  end

  private

  attr_reader :token_stream
end

class Liquider::TokenStream
  def initialize(content)
    @content = content.dup
    @mode = :text
  end

  def consume_text
    token = case content
    when /\A{{/ then MustacheBegin
    when /\A{%/ then TagOrBlockBegin
    when /.+?(?={{|{%|\z)/ then TextNode.new($&)
    end
    consume_n $&
    token
  end

  def consume_markup
    content =~ /\A.*?(?=}})/
    consume_n $&.length
    RawNode.new($&)
  end

  def consume_token(token)
    case content
    when /\A#{token.text}/
      consume_n $&.length
      token.new($&)
    else
      raise LiquidSyntaxError, "Expected '#{token.text}', but got '#{content[0..16]}...'."
    end
  end

  def consume_ident
    case content
    when /\A[:alpha:][[:alnum:]-]*(\?|!)?/
      consume_n $&.length
      Ident.new($&)
    else raise LiquidSyntaxError, "Expected identifier, but got '#{content[..16]}'."
    end
  end

  def consume_whitespace
    content =~ /\s*/
    consume_n $&.length
  end

  private

  attr_reader :content

  def consume_n(str, n)
    content[0..n] = ''
  end

  def summarize
    content[0..16] + (content.length < 16 ? '<EOF>' : '')
  end
end

__END__
qwerty asdf
{% form foo %}
  {% if a < 3 %}
    asdf
  {% endif %}
{% endform %}
qwer

Text("...") OpenBlock BlockIdent("form") Markup("foo ") CloseBlock Raw("{% ... %}") EndBlock Text("qwer")
