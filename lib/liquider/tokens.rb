module Liquider::Tokens
  module Scannable
    def check(string_scanner)
      match = string_scanner.check(pattern)
      return NullToken.new('', nil) if match.nil?
      new(match.to_s, nil)
    end
  end

  class Token
    attr_reader :text, :source_info

    def initialize(text, source_info)
      @text, @source_info = text, source_info
    end

    class << self
      include Scannable
    end

    def weight
      text.length
    end

    def ignore?
      false
    end

    def to_racc
      [token_name, text]
    end

    def next_mode(current_mode)
      :liquid
    end
  end

  class NullToken < Token
    def self.pattern
      %r<>
    end

    def initialize(text, source_info)
      super text, source_info
    end

    def token_name
      :NULL
    end

    def weight
      -1
    end

    def ignore?
      true
    end

    def to_s
      '#<Null>'
    end
  end

  class WhiteSpace < Token
    def self.pattern
      %r<\s+>
    end

    def token_name
      :WHITESPACE
    end

    def ignore?
      true
    end

    def next_mode(current_mode)
      current_mode
    end

    def to_s
      '#<WhiteSpace>'
    end
  end

  class Text < Token
    def self.pattern
      %r<{%\s*raw\s*%}>
    end

    def token_name
      :TEXT
    end

    def to_s
      %Q{#<Text "#{text}"}
    end
  end

  class Ident < Token
    def self.pattern
      %r<(?:[[:alpha:]]|_)(?:[[[:alpha:]][[:digit:]]\-_])*(?:!|\?)?>
    end

    def token_name
      :IDENT
    end

    def next_mode(current_mode)
      case current_mode
      when :tag_leader then :tag_markup
      else super
      end
    end

    def to_s
      %Q{#<Ident "#{text}">}
    end
  end

  class Atom < Token
    attr_reader :token_name

    def initialize(token_name, text, source_info)
      super text, source_info
      @token_name = token_name
    end

    def to_s
      "#<#{token_name}>"
    end
  end

  class AtomType
    attr_reader :token_name, :pattern

    def initialize(token_name, pattern)
      @token_name, @pattern = token_name, pattern
    end

    include Scannable

    def new(text, source_info)
      Atom.new(token_name, text, source_info)
    end
  end

  class TagOpen < Atom
    class << self
      def pattern
        %r<\{%>
      end
    end

    def initialize(text, source_info)
      super :TAGOPEN, text, source_info
    end

    def next_mode(current_mode)
      :tag_leader
    end
  end

  class TagClose < Atom
    class << self
      def pattern
        %r<%\}>
      end
    end

    def initialize(text, source_info)
      super :TAGCLOSE, text, source_info
    end

    def next_mode(current_mode)
      :text
    end
  end

  class Markup
    attr_reader :text

    def initialize(text, source_info)
      @text = text
    end

    def to_racc
      [:MARKUP, text]
    end
  end

  BlockTail  = AtomType.new(:BLOCKTAIL, %r<\{%\s*end\w+\s%\}>)

  class Eos
    class << self
      def check(text_stream)
        if text_stream.eos?
          self
        else
          NullToken.new('', 0)
        end
      end

      def token_name
        :EOS
      end

      def text
        ''
      end

      def ignore?
        false
      end

      def weight
        0
      end

      def to_racc
        [false, false]
      end

      def next_mode(current_mode)
        :eos
      end
    end
  end

  LEXEMES = [
    WhiteSpace,
    Text,
    Ident,
    AtomType.new(:NUMBER, %r<[0-9]+(?:\.[0-9]+)?>),
    AtomType.new(:STRING, %r<"[^"]*">),
    AtomType.new(:TRUE, %r<true>),
    AtomType.new(:TRUE, %r<false>),
    AtomType.new(:PIPE, %r<\|>),
    AtomType.new(:DOT, %r<\.\.>),
    AtomType.new(:DOTDOT, %r<\.\.>),
    AtomType.new(:COLON, %r<:>),
    AtomType.new(:COMMA, %r<,>),
    AtomType.new(:TIMES, %r<\*>),
    AtomType.new(:DIV, %r</>),
    AtomType.new(:PLUS, %r<\+>),
    AtomType.new(:MINUS, %r<->),
    AtomType.new(:EQ, %r<==>),
    AtomType.new(:NE, %r<!=>),
    AtomType.new(:LT, %r{<}),
    AtomType.new(:LE, %r{<=}),
    AtomType.new(:GT, %r{>}),
    AtomType.new(:GE, %r{>=}),
    AtomType.new(:CONTAINS, %r<contains>),
    AtomType.new(:MUSTACHEOPEN, %r<{{>),
    AtomType.new(:MUSTACHECLOSE, %r<}}>),
    TagOpen,
    TagClose,
    BlockTail,
    AtomType.new(:PARENTOPEN, %r<\(>),
    AtomType.new(:PARENTCLOSE, %r<\)>),
    Eos,
  ]
end
