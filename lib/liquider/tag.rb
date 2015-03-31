class Liquider::Tag < Struct.new(:markup, :document)
  extend Liquider::MarkupHelper

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
      markup = parse_arguments(source)
      return markup if markup.is_a?(Liquider::Ast::ArgListNode)
      raise LiquiderSyntaxError, "expected argument list"
    end
  end
end
