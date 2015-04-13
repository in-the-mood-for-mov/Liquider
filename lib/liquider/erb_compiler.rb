class Liquider::ErbCompiler
  attr_reader :output

  def initialize
    @context_open = false
    @variable_number = 0
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

  def on_boolean(bool)
    @output << bool.value.to_s
  end

  def on_nil(*)
    @output << "nil"
  end

  def on_tag(tag)
    tag.value.render_erb(self)
  end

  def on_negation(negation)
    wrap("!(",")") {
      negation.expression.visit(self)
    }
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

  def on_for(for_node)
    variable_name = "_liquider_var_#{@variable_number += 1}"
    erb_tag {
      for_node.expression.visit(self)
      unless for_node.offset.is_a?(NumberNode) && for_node.offset.value == 0
        wrap(".drop(", ")") {
          for_node.offset.visit(self)
        }
      end
      unless for_node.limit.is_a?(NilNode)
        wrap(".take(", ")") {
          for_node.limit.visit(self)
        }
      end

      @output << ".reverse" if for_node.reversed.value
      @output << ".each do |#{variable_name}|"
    }
    erb_tag {
      AssignNode.new(for_node.binding, LocalFetchNode.new(variable_name)).visit(self)
    }
    for_node.body.visit(self)
    erb_tag { @output << "end" }
  end

  def on_if(if_node)
    erb_tag {
      @output << "if "
      if_node.head.visit(self)
    }
    if_node.body.visit(self)
    erb_tag {
      @output << "else"
    }
    if_node.continuation.visit(self)
    erb_tag { @output << "end" }
  end

  def on_else(else_node)
    else_node.body.visit(self)
  end

  def on_case(case_node)
    erb_tag {
      @output << "case "
      case_node.head.visit(self)
    }
    case_node.cases.each do |branch|
      branch.visit(self)
    end
    erb_tag { @output << "end" }
  end

  def on_when(when_node)
    erb_tag {
      @output << "when "
      when_node.value.visit(self)
    }
    when_node.body.visit(self)
  end

  def on_case_else(when_node)
    erb_tag {
      @output << "else"
    }
    when_node.body.visit(self)
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

  def raw(str)
    @output << str
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
      wrap('"') {
        case opt_pair.value
        when StringNode, NumberNode, BooleanNode
          @output << opt_pair.value.value.to_s
        else
          erb_tag(output: true) {
            opt_pair.value.visit(self)
          }
        end
        }
    end
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

