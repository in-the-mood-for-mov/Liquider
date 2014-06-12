class Liquider::ErbCompiler
  attr_reader :output

  def initialize
    @output = ''
  end

  def on_document(document)
    document.elements.each do |element|
      element.visit(self)
    end
  end

  def on_text(text)
    @output << escape_erb(text.text)
  end

  def on_mustache(mustache)
    wrap('<%= ', ' %>') { mustache.expression.visit(self) }
  end

  def on_filter(filter)
    @output << filter.message
    wrap('(', ')') { filter.arg_list.visit(self) }
  end

  def on_arg_list(arg_list)
    has_optionals = arg_list.optionals.any?
    arg_list.positionals.each do |positional|
      positional.visit(self)
      @output << ', ' unless positional == arg_list.positionals.last && !has_optionals
    end
    return unless has_optionals
    wrap('{', '}') do
      arg_list.optionals.each do |optional|
        wrap("'") { @output << optional.key }
        @output << ' => '
        optional.value.visit(self)
        @output << ', ' unless optional == arg_list.optionals.last
      end
    end
  end

  def on_binop(binop)
    binop.left.visit(self)
    wrap(' ', ' ') { @output << binop.op.to_s }
    binop.right.visit(self)
  end

  def on_symbol(symbol)
    @output << "@context['" << symbol.name << "']"
  end

  def on_string(string)
    @output << "'" << string.value.gsub(/'/, "\\\\'") << "'"
  end

  def on_number(number)
    @output << number.value.to_s
  end

  def on_call(call)
    call.target.visit(self)
    @output << '.' << call.property.name
  end

  def on_index(index)
    index.target.visit(self)
    wrap('[', ']') { index.property.visit(self) }
  end

  def on_parenthesis(parenthesis)
    wrap('(', ')') { parenthesis.expression.visit(self) }
  end

  def on_html_tag(tag)
    open_html_tag(tag)
    @output << '/>'
  end

  def on_html_block(block)
    open_html_tag(block)
    @output << '>'
    block.body.visit(self)
    @output << '</' << block.tag_name.to_s << '>'
  end

  private
  def wrap(start, finish = nil)
    @output << start
    yield
    @output << (finish || start)
  end

  def open_html_tag(tag)
    @output << '<' << tag.tag_name.to_s
    tag.opt_list.each do |opt_pair|
      @output << ' ' << opt_pair.key << '='
      if opt_pair.value.kind_of?(LiteralNode)
        opt_pair.value.visit(self)
      else
        @output << '"<%= '
        opt_pair.value.visit(self)
        @output << ' %>"'
      end
    end
  end

  def escape_erb(text)
    text.gsub(/<%/, '<%%')
  end

  module Ast
    class HtmlBlock
      attr_reader :tag_name, :opt_list, :body

      def initialize(tag_name, opt_list, body)
        @tag_name = tag_name
        @opt_list = opt_list
        @body = body
      end

      def visit(visitor)
        visitor.on_html_block(self)
      end
    end

    class HtmlTag
      attr_reader :tag_name, :opt_list

      def initialize(tag_name, opt_list)
        @tag_name = tag_name
        @opt_list = opt_list
      end

      def visit(visitor)
        visitor.on_html_tag(self)
      end
    end

    class LocalAssign
      attr_reader :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end

      def visit(visitor)
        visitor.local_assign(self)
      end
    end

    class LocalFetch
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def visit(visitor)
        visitor.local_fetch(self)
      end
    end

    class Capture
      attr_reader :body

      def initialize(body)
        @body = body
      end

      def visit(visitor)
        visitor.capture(self)
      end
    end

    class ContextStack
      def visit(visitor)
        visitor.context_stack(self)
      end
    end
  end
end

