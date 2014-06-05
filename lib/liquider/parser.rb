class Liquider::Parser < Liquider::GeneratedParser
  def parse(test_stream)
    @text_stream = text_stream
    do_parse
  end

  private

  def next_token
  end
end
