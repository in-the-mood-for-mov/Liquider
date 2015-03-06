module Liquider::Tags
  class Block
    def self.block?
      true
    end
  end

  class Tag
    def self.block?
      false
    end
  end
end

require 'liquider/tags/cycle'
require 'liquider/tags/paginate'
