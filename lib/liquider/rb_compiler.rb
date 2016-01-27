class Liquider::RbCompiler
  attr_reader :output

  def initialize
    @context_open = false
    @context_stack = 0
    @variable_number = 0
    @output = ""
  end

  def register(statement)
    @output << statement
  end

  def assign(expression)
    "@rb_output << #{expression}\n"
  end

  def on_document(document)
    document.elements.each do |element|
      element.visit(self)
    end
  end

  def on_text(text)
    register(assign(text.text.inspect))
  end

  def on_mustache(mustache)
    rb_tag(output: true) { mustache.expression.visit(self) }
  end

  def on_assign(assign)
    register("@context['#{assign.binding.name}'] = ")
    assign.value.visit(self)
  end

  def on_filter(filter)
    register(filter.message)
    wrap('(', ')') { filter.arg_list.visit(self) }
  end

  def on_arg_list(arg_list)
    has_optionals = arg_list.optionals.any?
    arg_list.positionals.each do |positional|
      positional.visit(self)
      register(', ') unless positional == arg_list.positionals.last && !has_optionals
    end
    return unless has_optionals
    wrap('{', '}') do
      arg_list.optionals.each do |optional|
        register(optional.key.inspect)
        register(' => ')
        optional.value.visit(self)
        register(', ') unless optional == arg_list.optionals.last
      end
    end
  end

  def on_binop(binop)
    binop.left.visit(self)
    wrap(' ', ' ') { register(binop.op.to_s) }
    binop.right.visit(self)
  end

  def on_symbol(symbol)
    wrap_in_context {
      register(symbol.name)
    }
  end

  def on_string(string)
    register(string.value.inspect)
  end

  def on_number(number)
    register(number.value.to_s)
  end

  def on_boolean(bool)
    register(bool.value.to_s)
  end

  def on_nil(*)
    register("nil")
  end

  def on_tag(tag)
    tag.value.render_rb(self)
  end

  def on_negation(negation)
    wrap("!(",")") {
      negation.expression.visit(self)
    }
  end

  def on_call(call)
    wrap_in_context do
      call.target.visit(self)
      register('.' << call.property.name)
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
    register('/>')
  end

  def on_html_block(block)
    open_html_tag(block)
    register('>')
    block.body.visit(self)
    register('</' << block.tag_name.to_s << '>')
  end

  def on_capture(capture)
    rb_tag {
      register(capture.name << " = capture do")
    }
    capture.body.visit(self)
    rb_tag {
      register("end")
    }
  end

  def on_local_assign(local_assign)
    rb_tag {
      register(local_assign.name << ' = ')
      local_assign.value.visit(self)
    }
  end

  def on_local_fetch(local_fetch)
    register(local_fetch.name)
  end

  def on_for(for_node)
    variable_name = "_liquider_var_#{@variable_number += 1}"
    rb_tag {
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

      register(".reverse") if for_node.reversed.value
      register(".each do |#{variable_name}|")
    }
    rb_tag {
      AssignNode.new(for_node.binding, LocalFetchNode.new(variable_name)).visit(self)
    }
    for_node.body.visit(self)
    rb_tag { register("end") }
  end

  def on_if(if_node)
    rb_tag {
      register("if ")
      if_node.head.visit(self)
    }
    if_node.body.visit(self)
    rb_tag {
      register("else")
    }
    if_node.continuation.visit(self)
    rb_tag { register("end") }
  end

  def on_else(else_node)
    else_node.body.visit(self)
  end

  def on_case(case_node)
    rb_tag {
      register("case ")
      case_node.head.visit(self)
    }
    case_node.cases.each do |branch|
      branch.visit(self)
    end
    rb_tag { register("end") }
  end

  def on_when(when_node)
    rb_tag {
      register("when ")
      when_node.value.visit(self)
    }
    when_node.body.visit(self)
  end

  def on_case_else(when_node)
    rb_tag {
      register("else")
    }
    when_node.body.visit(self)
  end

  def on_context_stack(context_stack)
    rb_tag {
      register("@context.stack do")
    }

    context_stack.body.visit(self)

    rb_tag {
      register("end")
    }
  end

  def raw(str)
    register(str)
  end

  def rb_tag(output: false)
    raise Liquider::LiquiderSyntaxError, "RB statement already open" if @rb_open
    @rb_open = true
    previous_output = @output
    @output = ""
    yield
    new_content = @output + "\n"
    @output = previous_output
    if output
      register(assign(new_content))
    else
      register(new_content)
    end
  ensure
    @rb_open = false
  end

  private

  def wrap_in_context
    if !@context_open
      @context_open = true
      register("@context['")
      buffer, @output = @output, ""
      yield
      buffer << output.gsub(/'/, "\\\\'")
      @output = buffer
      register("']")
      @context_open = false
    else
      yield
    end
  end

  def wrap(start, finish = nil)
    register(start)
    yield
    register((finish || start))
  end

  module Ast
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
