module Liquider::Tokens

  class Token
    attr_reader :text

    def initialize(text)
      @text = text
    end
  end

  class Text < Token; end

  class Ident < Token
    def self.pattern
      %r<^(?:[[:alpha:]]|_)(?:[[[:alpha:]][[:digit:]]-_])*(?:!|\?)?>
    end
  end

  class MustacheOpen < Token
    def self.pattern
      %r<^{%>
    end
  end

  class MustacheClose < Token
    def self.pattern
      %r<^%}>
    end
  end

  class DoubleMustacheOpen < Token
    def self.pattern
      %r<^{{>
    end
  end

  class DoubleMustacheClose < Token
    def self.pattern
      %r<^}}>
    end
  end

  class ParenOpen < Token
    def self.pattern
      %r<^\(>
    end
  end

  class ParenClose < Token
    def self.pattern
      %r<^\)>
    end
  end

  class Range < Token
    def self.pattern
      %<^\.\.>
    end
  end

  class BinaryOp < Token
    def self.pattern
      %r{^(?:(?:==)|(?:/=)|(?:>=)|(?:<=)|(?:>)|(?:<)|\+|-|\*|/)}
    end
  end

  class Filter < Token
    def self.pattern
      %r<\|>
    end
  end

  class Comma < Token
    def self.pattern
      %r<,>
    end
  end

  class Quote < Token
    def self.pattern
      %r<'>
    end
  end

  class DoubleQuote < Token
    def self.pattern
      %r<">
    end
  end

end
