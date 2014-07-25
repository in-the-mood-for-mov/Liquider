class Liquider::ErbCompiler
  attr_reader :output

  def initialize
    @context_open = false
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
    erb_tag(output: true) { mustache.expression.visit(self) }
  end

  def on_assign(assign)
    assign.binding.visit(self)
    @output << " = "
    assign.value.visit(self)
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
    wrap_in_context {
      @output << symbol.name
    }
  end

  def on_string(string)
    @output << "'" << string.value.gsub(/'/, "\\\\'") << "'"
  end

  def on_number(number)
    @output << number.value.to_s
  end

  def on_call(call)
    wrap_in_context do
      call.target.visit(self)
      @output << '.' << call.property.name
    end
  end

  def on_index(index)
    wrap_in_context {
      index.target.visit(self)
      wrap('[', ']') { index.property.visit(self) }
    }
  end

  def on_parenthesised(parenthesis)
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

  def on_capture(capture)
    erb_tag {
      @output << capture.name << " = capture do"
    }
    capture.body.visit(self)
    erb_tag {
      @output << "end"
    }
  end

  def on_local_assign(local_assign)
    erb_tag {
      @output << local_assign.name << ' = '
      local_assign.value.visit(self)
    }
  end

  def on_local_fetch(local_fetch)
    @output << local_fetch.name
  end

  def on_context_stack(context_stack)
    erb_tag {
      @output << "@context.stack do"
    }

    context_stack.body.visit(self)

    erb_tag {
      @output << "end"
    }
  end

  private
  def wrap_in_context
    if !@context_open
      @context_open = true
      @output << "@context['"
      buffer, @output = @output, ""
      yield
      buffer << output.gsub(/'/, "\\\\'")
      @output = buffer
      @output << "']"
      @context_open = false
    else
      yield
    end
  end

  def wrap(start, finish = nil)
    @output << start
    yield
    @output << (finish || start)
  end

  def open_html_tag(tag)
    @output << '<' << tag.tag_name.to_s
    tag.opt_list.each do |opt_pair|
      @output << ' ' << opt_pair.key << '='
      if [StringNode, NumberNode, BooleanNode].any? { |node_type| opt_pair.value.is_a?(node_type) }
        opt_pair.value.visit(self)
      else
        wrap('"') {
          erb_tag(output: true) {
            opt_pair.value.visit(self)
          }
        }
      end
    end
  end

  def erb_tag(output: false)
    raise Liquider::LiquiderSyntaxError, "ERB statement already open" if @erb_open
    @erb_open = true
    @output << "<%#{'=' if output} "
    yield
    @output << " %>"
  ensure
    @erb_open = false
  end

  def escape_erb(text)
    text.gsub(/<%/, '<%%')
  end

  module Ast
    class HtmlBlockNode
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

    class HtmlTagNode
      attr_reader :tag_name, :opt_list

      def initialize(tag_name, opt_list)
        @tag_name = tag_name
        @opt_list = opt_list
      end

      def visit(visitor)
        visitor.on_html_tag(self)
      end
    end

    class LocalAssignNode
      attr_reader :name, :value

      def initialize(name, value)
        @name = name
        @value = value
      end

      def visit(visitor)
        visitor.on_local_assign(self)
      end
    end

    class LocalFetchNode
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def visit(visitor)
        visitor.on_local_fetch(self)
      end
    end

    class CaptureNode
      attr_reader :name, :body

      def initialize(name, body)
        @name = name
        @body = body
      end

      def visit(visitor)
        visitor.on_capture(self)
      end
    end

    class ContextStackNode
      attr_reader :body

      def initialize(body)
        @body = body
      end

      def visit(visitor)
        visitor.on_context_stack(self)
      end
    end
  end
end

