module Liquider::Ast
  class Node
  end

  class Document < Node
    def initialize(elements)
      @elements = elements
    end

    def ==(other)
      elements == other.elements
    end

    protected

    attr_reader :elements
  end

  class Text < Node
    def initialize(text)
      @text = text
    end

    def ==(other)
      text == other.text
    end

    protected

    attr_reader :text
  end

  class Mustache < Node
    def initialize(expression)
      @expression = expression
    end

    def ==(other)
      expression == other.expression
    end

    protected

    attr_reader :expression
  end

  class BinOp < Node
    def initialize(left, right, op)
      @left, @right, @op = left, right, op
    end

    def ==(other)
      left == other.left and
      right == other.right and
      op == other.op
    end

    protected

    attr_reader :left, :right, :op
  end

  class Call < Node
    def initialize(target, property)
      @target, @property = target, property
    end

    def ==(other)
      target == other.target and
      property == other.property
    end

    protected

    attr_reader :target, :property
  end

  class Index < Node
    def initialize(target, property)
      @target, @property = target, property
    end

    def ==(other)
      target == other.target and
      property == other.property
    end

    protected

    attr_reader :target, :property
  end

  class Symbol < Node
    def initialize(name)
      @name = name
    end

    def ==(other)
      name == other.name
    end

    protected

    attr_reader :name
  end

  class Literal < Node
    def initialize(value)
      @value = value
    end

    def ==(other)
      other.instance_of?(Literal) and
      value == other.value
    end

    protected

    attr_reader :value
  end

  class Parenthesised < Node
    def initialize(expression)
      @expression = expression
    end

    def ==(other)
      expression == other.expression
    end

    protected

    attr_reader :expression
  end
end
