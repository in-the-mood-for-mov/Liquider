module Liquider::Ast
  class Node
    class << self
      def new_type(type_name, *attributes)
        type = Class.new(Node)

        attributes.each do |attribute|
          type.class_eval do
            attr_reader attribute
          end
        end

        type.class_eval(<<-INITIALIZE)
          def initialize(#{attributes.join(',')})
            #{attributes.map { |attribute| "@#{attribute}" }.join(',')} = #{attributes.join(',')}
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

        type
      end
    end
  end

  DocumentNode = Node.new_type(:document, :elements)
  TextNode = Node.new_type(:text, :text)
  MustacheNode = Node.new_type(:mustache, :expression)
  TagNode = Node.new_type(:tag, :node_name, :markup, :body)
  FilterNode = Node.new_type(:filter, :message, :arg_list)
  ArgListNode = Node.new_type(:arg_list, :positionals, :optionals)
  OptionPairNode = Node.new_type(:option_pair, :key, :value)
  NegationNode = Node.new_type(:negation, :expression)
  BinOpNode = Node.new_type(:binop, :left, :right, :op)
  CallNode = Node.new_type(:call, :target, :property)
  IndexNode = Node.new_type(:index, :target, :property)
  SymbolNode = Node.new_type(:symbol, :name)
  StringNode = Node.new_type(:string, :value)
  NumberNode = Node.new_type(:number, :value)
  BooleanNode = Node.new_type(:boolean, :value)
  ParenthesisedNode = Node.new_type(:parenthesised, :expression)
  IfNode = Node.new_type(:if, :table)
end
