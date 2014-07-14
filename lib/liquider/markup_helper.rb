module Liquider::MarkupHelper
  def tokenize(source)
    Scanner.new(TextStream.new(source, mode: :liquid)).to_enum
  end

  def split_on_keyword(keyword, tokens)
    keyword = keyword.to_s
    chunks = tokens.slice_before { |token| token == [:IDENT, keyword] }.to_a
    [chunks[0]] + chunks[1..-1].map { |chunk| chunk[1..-1] }
  end

  def parse_expression(tokens)
    Parser.new([:GOTOEXPRESSION, ''] + tokens).parse
  end

  def parse_arguments(tokens)
    Parser.new([:GOTOARGLIST, ''] + tokens).parse
  end
end
