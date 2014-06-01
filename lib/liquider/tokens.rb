module Liquider::Tokens

  class Token
    attr_reader :text, :line, :column

    def initialize(text, line, column)
      @text = text
      @line, @column = line, column
    end
  end

  class Text < Token
    def to_s
      %Q{#<Text "#{text}"}
    end
  end

  class Ident < Token
    def self.pattern
      %r<\A(?:[[:alpha:]]|_)(?:[[[:alpha:]][[:digit:]]-_])*(?:!|\?)?>
    end

    def to_s
      %Q{#<Ident "#{text}">}
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
