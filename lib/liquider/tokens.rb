module Liquider::Tokens
  include Liquider

  WhiteSpace = Token.new_type(:WHITESPACE, /\s*/m) do
    def ignore?
      true
    end
  end

  TextToken = Token.new_type(:TEXT, %r<.*?(?:\z|(?=\{\{)|(?=\{%))>m) do
    def next_mode(current_mode)
      return :enter_liquid
    end

    def ignore?
      text.empty?
    end
  end

  RawTextToken = Token.new_type(:TEXT, %r<\{%\s*raw\s*%\}(.*?)\{%\s*endraw\s*\}>) do
    def text
      @raw_text ||= text.gsub(/\A\{%\s*raw\s*%\}/, '').gsub(/\{%\s*endraw\s*%\}\z/, '')
    end

    def next_mode(current_mode)
      return :text
    end
  end

  IdentToken = Token.new_type(:IDENT, %r<[[[:alpha:]]_][[[:alpha:]][[:digit:]]\-_]*[!\?]?>) do
    def next_mode(current_mode)
      case current_mode
      when :tag_leader then :markup
      else super
      end
    end
  end

  NumberToken = Token.new_type(:NUMBER, %r<[0-9]+(?:\.[0-9]+)?>)
  StringToken = Token.new_type(:STRING, %r<"[^"]*">)
  TrueToken = Token.new_type(:TRUE, %r<true>)
  FalseToken = Token.new_type(:FALSE, %r<false>)
  PipeToken = Token.new_type(:PIPE, %r<\|>)
  DotToken = Token.new_type(:DOT, %r<\.\.>)
  DoubleDotToken = Token.new_type(:DOUBLEDOT, %r<\.\.>)
  ColonToken = Token.new_type(:COLON, %r<:>)
  CommaToken = Token.new_type(:COMMA, %r<,>)
  TimesToken = Token.new_type(:TIMES, %r<\*>)
  DivToken = Token.new_type(:DIV, %r</>)
  PlusToken = Token.new_type(:PLUS, %r<\+>)
  MinusToken = Token.new_type(:MINUS, %r<->)
  EqToken = Token.new_type(:EQ, %r<==>)
  NeToken = Token.new_type(:NE, %r<!=>)
  LtToken = Token.new_type(:LT, %r{<})
  LeToken = Token.new_type(:LE, %r{<=})
  GtToken = Token.new_type(:GT, %r{>})
  GeToken = Token.new_type(:GE, %r{>=})
  ContainsToken = Token.new_type(:CONTAINS, %r<contains>)
  ParenOpenToken = Token.new_type(:PARENOPEN, %r<\(>)
  ParenCloseToken = Token.new_type(:PARENCLOSE, %r<\)>)

  MustacheOpenToken = Token.new_type(:MUSTACHEOPEN, %r<\{\{>) do
    def next_mode(current_mode)
      :liquid
    end
  end

  MustacheCloseToken = Token.new_type(:MUSTACHECLOSE, %r<}}>) do
    def next_mode(current_mode)
      :text
    end
  end

  TagOpenToken = Token.new_type(:TAGOPEN, Regexp.new('\{%\s*' + IdentToken.pattern.source)) do
    def next_mode(current_mode)
      :markup
    end
  end

  TagCloseToken = Token.new_type(:TAGCLOSE, %r<%\}>) do
    def next_mode(current_mode)
      :text
    end
  end

  IfToken = Token.new_tag_leader(:IF)
  ElsifToken = Token.new_tag_leader(:ELSIF)
  ElseToken = Token.new_text_keyword(:ELSE)
  EndIfToken = Token.new_text_keyword(:ENDIF)

  UnlessToken = Token.new_tag_leader(:UNLESS)
  EndUnlessToken = Token.new_text_keyword(:ENDUNLESS)

  CaseToken = Token.new_tag_leader(:CASE)
  WhenToken = Token.new_tag_leader(:WHEN)
  EndCaseToken = Token.new_text_keyword(:ENDCASE)

  ForToken = Token.new_tag_leader(:FOR)
  InToken = Token.new_expr_keyword(:IN)
  EndForToken = Token.new_text_keyword(:ENDFOR)

  EndBlockToken = Token.new_type(:ENDBLOCK, Regexp.new('\{%\s*end' + IdentToken.pattern.source + '\s*%\}')) do
    def next_mode(current_mode)
      :text
    end
  end


  MarkupToken = Token.new_type(:MARKUP, %r<.*?(?=\z|(?=\%\}))>) do
    def next_mode(current_mode)
      :liquid
    end
  end

  BlockTail = Token.new_type(:BLOCKTAIL, %r<\{%\s*end\w+\s%\}>)

  EosToken = Token.new_type(:EOS, %r<\z>) do
    def to_racc
      [false, false]
    end

    def next_mode(current_mode)
      :eos
    end
  end

  NullToken = Token.new_type(:NULL, %r<.\A>) do
    def weight
      -1
    end

    def ignore?
      true
    end

    def raise_on_error(tokens, text_stream)
      raise LiquiderSyntaxError.new(%Q{Expected one of #{humanize_tokens tokens}, but found "#{text_stream.summarize}".})
    end

    private

    def humanize_tokens(tokens)
      case tokens.length
      when 0 then 'nothing'
      when 1 then tokens.first.to_s
      else tokens[0...-1].map(&:to_s).join(', ') + ', or ' + tokens[-1].to_s
      end
    end
  end
end
