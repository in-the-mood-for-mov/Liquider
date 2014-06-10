require 'liquider'
require 'pry'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end

module Liquider::Spec
  class TestBlock
    class << self
      def block?
        true
      end

      def parse_markup(source)
        :markup
      end
    end
  end

  class TestTag
    class << self
      def block?
        false
      end

      def parse_markup(source)
        :markup
      end
    end
  end

  TAGS = {
    'block' => TestBlock,
    'tag' => TestTag,
  }
end
