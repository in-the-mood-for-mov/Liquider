module Liquider::Ast
  class Node
    class << self
      def new_type(type_name, *attributes, &block)
        type = Class.new(Node) do
          attr_reader :options

          attributes.each do |attribute|
            attr_reader attribute
          end
        end

        type.class_eval(<<-INITIALIZE)
          def initialize(#{attributes.join(',')}, **options)
            #{attributes.map { |attribute| "@#{attribute}" }.join(',')} = #{attributes.join(',')}
            @options = options
          end
        INITIALIZE

        type.class_eval(<<-EQUALS)
          def ==(other)
            return false unless self.class == other.class
            #{attributes.map { |attribute| "#{attribute} == other.#{attribute}" }.join(' && ')}
          end
        EQUALS

        type.class_eval(<<-VISIT)
          def visit(visitor)
            visitor.on_#{type_name}(self)
          end
        VISIT

        type.class_eval(&block) if block

        type
      end
    end
  end

  DocumentNode = Node.new_type(:document, :elements)
  TextNode = Node.new_type(:text, :text)
  MustacheNode = Node.new_type(:mustache, :expression)
  TagNode = Node.new_type(:tag, :value)
  FilterNode = Node.new_type(:filter, :message, :arg_list)
  ArgListNode = Node.new_type(:arg_list, :positionals, :optionals)
  OptionPairNode = Node.new_type(:option_pair, :key, :value)
  NegationNode = Node.new_type(:negation, :expression)
  BinOpNode = Node.new_type(:binop, :op, :left, :right)
  CallNode = Node.new_type(:call, :target, :property)
  IndexNode = Node.new_type(:index, :target, :property)
  SymbolNode = Node.new_type(:symbol, :name)
  StringNode = Node.new_type(:string, :value)
  NumberNode = Node.new_type(:number, :value)
  BooleanNode = Node.new_type(:boolean, :value)

  class NilNode < Node
    def ==(other)
      self.class == other.clas
    end

    def visit(visitor)
      visitor.on_nil(self)
    end
  end

  ParenthesisedNode = Node.new_type(:parenthesised, :expression)
  IfNode = Node.new_type(:if, :head, :body, :continuation)
  ElseNode = Node.new_type(:else, :body)
  CaseNode = Node.new_type(:case, :head, :cases)
  WhenNode = Node.new_type(:when, :value, :body)
  CaseElseNode = Node.new_type(:case_else, :body)

  ForNode = Node.new_type(:for, :binding, :expression, :body) do
    def reversed
      options[:reversed] || Ast::BooleanNode.new(false)
    end

    def limit
      options[:limit] || Ast::NilNode.new
    end

    def offset
      options[:offset] || Ast::NumberNode.new(0)
    end
  end

  AssignNode = Node.new_type(:assign, :binding, :value)
  CaptureNode = Node.new_type(:capture, :binding, :document)

  class NullNode < Node
    def ==(other)
      self.class == other.class
    end

    def visit(visitor)
    end
  end
end
