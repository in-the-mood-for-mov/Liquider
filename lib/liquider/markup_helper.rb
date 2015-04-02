module Liquider::MarkupHelper
  def tokenize(source, mode: :text)
    Liquider::Scanner.new(Liquider::TextStream.new(source), mode: mode).to_enum
  end

  def split_on_keyword(keyword, tokens)
    keyword = keyword.to_s
    chunks = tokens.slice_before { |token| token == [:IDENT, keyword] }.to_a
    [chunks[0]] + chunks[1..-1].map { |chunk| chunk[1..-1] }
  end

  def parse_expression(source)
    Liquider::Parser.new({}, [[:GOTOEXPRESSION, ''], *tokenize(source, mode: :liquid)]).parse
  end

  def parse_arguments(source)
    Liquider::Parser.new({}, [[:GOTOARGLIST, ''], *tokenize(source, mode: :liquid)]).parse
  end
end
