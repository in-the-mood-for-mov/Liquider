class Liquider::Tag
  attr_reader :markup, :document

  def initialize(markup, document)
    @markup = markup
    @document = document
  end

  class << self
    def block?
      false
    end

    def parse_markup(source)
      markup = Liquider::Parser.new({}, source).parse
      raise LiquiderSyntaxError unless markup.is_a?(Liquider::Ast::ArgListNode)
      markup
    end
  end
end
