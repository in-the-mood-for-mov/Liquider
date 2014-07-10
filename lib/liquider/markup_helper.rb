module Liquider::MarkupHelper
  def tokenize(source)
    Scanner.new(TextStream.new(source, mode: :liquid)).to_enum
  end

  def parse_expression(tokens)
    Parser.new([:GOTOEXPRESSION, ''] + tokens).parse
  end

  def parse_arguments(tokens)
    Parser.new([:GOTOARGLIST, ''] + tokens).parse
  end
end
