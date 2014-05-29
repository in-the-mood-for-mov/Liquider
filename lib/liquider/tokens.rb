module Liquider::Tokens

  class Token
    attr_reader :text

    def initialize(text, line, column)
      @text = text
    end
  end

  class Text < Token; end

  class Ident < Token
    def self.pattern
      %r<\A(?:[[:alpha:]]|_)(?:[[[:alpha:]][[:digit:]]-_])*(?:!|\?)?>
    end
  end

  class TagOpen < Token
    def self.pattern
      %r<\A{%>
    end
  end

  class TagClose < Token
    def self.pattern
      %r<\A%}>
    end
  end

  class MustacheOpen < Token
    def self.pattern
      %r<\A{{>
    end
  end

  class MustacheClose < Token
    def self.pattern
      %r<\A}}>
    end
  end

  class ParenOpen < Token
    def self.pattern
      %r<\A\(>
    end
  end

  class ParenClose < Token
    def self.pattern
      %r<\A\)>
    end
  end

  class Range < Token
    def self.pattern
      %<\A\.\.>
    end
  end

  class BinaryOp < Token
    def self.pattern
      %r{\A(?:(?:==)|(?:!=)|(?:>=)|(?:<=)|>|<|\+|-|\*|/)}
    end
  end

  class Filter < Token
    def self.pattern
      %r<\A\|>
    end
  end

  class Comma < Token
    def self.pattern
      %r<\A,>
    end
  end

  class Quote < Token
    def self.pattern
      %r<\A'>
    end
  end

  class DoubleQuote < Token
    def self.pattern
      %r<\A">
    end
  end

end
