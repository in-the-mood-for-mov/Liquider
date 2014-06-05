module Liquider::Ast
  class DocumentNode
    attr_reader :elements

    def initialize(elements)
      @elements = elements
    end

    def ==(other)
      elements == other.elements
    end

    def visit(compiler)
      compiler.on_document(self)
    end
  end

  class TextNode
    attr_reader :text

    def initialize(text)
      @text = text
    end

    def ==(other)
      text == other.text
    end

    def visit(compiler)
      compiler.on_text(self)
    end
  end

  class MustacheNode
    attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def ==(other)
      expression == other.expression
    end

    def visit(compiler)
      compiler.on_mustache(self)
    end
  end

  class BinOpNode
    attr_reader :left, :right, :op

    def initialize(left, right, op)
      @left, @right, @op = left, right, op
    end

    def ==(other)
      left == other.left and
      right == other.right and
      op == other.op
    end

    def visit(compiler)
      compiler.on_binop(self)
    end
  end

  class CallNode
    attr_reader :target, :property

    def initialize(target, property)
      @target, @property = target, property
    end

    def ==(other)
      target == other.target and
      property == other.property
    end

    def visit(compiler)
      compiler.on_call(self)
    end
  end

  class IndexNode
    attr_reader :target, :property

    def initialize(target, property)
      @target, @property = target, property
    end

    def ==(other)
      target == other.target and
      property == other.property
    end

    def visit(compiler)
      compiler.on_index(self)
    end
  end

  class SymbolNode
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def ==(other)
      name == other.name
    end

    def visit(compiler)
      compiler.on_symbol(self)
    end
  end

  class LiteralNode
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def ==(other)
      other.is_a?(LiteralNode) and
      value == other.value
    end
  end

  class StringNode < LiteralNode
    def visit(compiler)
      compiler.on_string(self)
    end
  end

  class NumberNode < LiteralNode
    def visit(compiler)
      compiler.on_number(self)
    end
  end

  class ParenthesisedNode
    attr_reader :expression

    def initialize(expression)
      @expression = expression
    end

    def ==(other)
      expression == other.expression
    end

    def visit(compiler)
      compiler.on_parenthesis(self)
    end
  end
end
