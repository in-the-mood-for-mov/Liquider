class Liquider::ErbCompiler
  attr_reader :output

  def initialize
    @output = ""
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
    wrap("<%= ", " %>") { mustache.expression.visit(self) }
  end

  def on_filter(filter)
    @output << filter.message
    wrap("(", ")") { filter.arg_list.visit(self) }
  end

  def on_arg_list(arg_list)
    has_optionals = arg_list.optionals.any?
    arg_list.positionals.each do |positional|
      positional.visit(self)
      @output << ", " unless positional == arg_list.positionals.last && !has_optionals
    end
    return unless has_optionals
    wrap("{", "}") do
      arg_list.optionals.each do |optional|
        wrap("'") { @output << optional.key }
        @output << ' => '
        optional.value.visit(self)
        @output << ", " unless optional == arg_list.optionals.last
      end
    end
  end

  def on_binop(binop)
    binop.left.visit(self)
    wrap(" ", " ") { @output << binop.op.to_s }
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
    @output << "." << call.property.name
  end

  def on_index(index)
    index.target.visit(self)
    wrap("[", "]") { index.property.visit(self) }
  end

  def on_parenthesis(parenthesis)
    wrap("(", ")") { parenthesis.expression.visit(self) }
  end

  private
  def wrap(start, finish = nil)
    @output << start
    yield
    @output << (finish || start)
  end

  def escape_erb(text)
    text.gsub(/<%/, "<%%")
  end
end


