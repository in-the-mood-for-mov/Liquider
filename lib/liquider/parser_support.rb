class Liquider::LiquiderSyntaxError < Exception
end

class Liquider::BlockHead
  attr_reader :tag_name, :markup

  def initialize(tag_name, markup)
    @tag_name, @markup = tag_name, markup
  end
end

class Liquider::BlockTail
  class << self
    def from_token(source)
      source =~ /{%\s*end(\w+)\s*%}/
      new $1
    end
  end

  attr_reader :tag_name

  def initialize(tag_name)
    @tag_name = tag_name
  end
end
