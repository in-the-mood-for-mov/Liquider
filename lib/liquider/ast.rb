module Liquider::Ast
  class Node
    class << self
      def new_type(type_name, *attributes, modules: [])
        type = Class.new(Node) do
          modules.each do |mod|
            include mod
          end

          attributes.each do |attribute|
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

    def on_litteral
    end

    def on_boolean
    end
  end

  module LitteralNode
    def on_litteral
      yield self
    end
  end

  module BooleanNode
    def on_boolean
      yield self
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
  StringNode = Node.new_type(:string, :value, modules: [LitteralNode])
  NumberNode = Node.new_type(:number, :value, modules: [LitteralNode])
  BooleanNode = Node.new_type(:boolean, :value, modules: [LitteralNode, BooleanNode])
  ParenthesisedNode = Node.new_type(:parenthesised, :expression)
  IfNode = Node.new_type(:if, :table)
  CaseNode = Node.new_type(:case, :head, :cases)
  WhenNode = Node.new_type(:when, :value, :body)
  CaseElseNode = Node.new_type(:case_else, :body)
  ForNode = Node.new_type(:for, :binding, :expression, :body)
  AssignNode = Node.new_type(:assign, :binding, :value)
end
