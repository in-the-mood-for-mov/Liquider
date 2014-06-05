class Liquider::AwesomePrinter
  attr_reader :out

  def initialize(out)
    @indent = 0
    @out = out
  end

  def on_document(document)
    out << indent("#<Document elements=[\n")
    indented do
      document.elements.each do |element|
        element.visit(self)
      end
    end
    out << indent("]>\n")
  end

  def on_text(text)
    out << indent("#<Text text=\"#{text.text}\">\n")
  end

  def on_mustache(mustache)
    out << indent("#<Mustache expression=[\n")
    indented do
      mustache.expression.visit(self)
    end
    out << indent("]>\n")
  end

  def on_binop(binop)
    out << indent("#<BinOp left=[\n")
    indented do
      binop.left.visit(self)
    end
    out << indent("] right=[\n")
    indented do
      binop.right.visit(self)
    end
    out << indent("] op=#{binop.op}>\n")
  end

  def on_symbol(symbol)
    out << indent("#<Symbol value=#{symbol.name}>\n")
  end

  def on_string(string)
    out << indent("#<String value=#{string.value}>\n")
  end

  def on_number(number)
    out << indent("#<Number value=#{number.value}>\n")
  end

  def on_call(call)
    out << indent("#<Call target=[\n")
    indented do
      call.target.visit(self)
    end
    out << indent("] property=#{call.property}>\n")
  end

  def on_index(index)
    out << indent("#<Index target=[\n")
    indented do
      index.target.visit(self)
    end
    out << indent("] property=[\n")
    indented do
      index.property.visit(self)
    end
    out << indent("]>\n")
  end

  def on_parenthesis(parenthesis)
    out << indent("#<Parenthesis (\n")
    indented do
      parenthesis.expression.visit(self)
    end
    out << indent(")>\n")
  end

  private
  def indented
    @indent += 1
    yield
    @indent -= 1
  end

  def indent(string)
    " " * (@indent * 2) + string
  end
end
