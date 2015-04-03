class Liquider::Tag < Struct.new(:markup, :document)
  extend Liquider::MarkupHelper

  def render_erb(compiler)
    raise NoMethodError
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
