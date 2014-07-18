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

module TokenSpecHelper
  def t_ident(value)
    [:IDENT, value.to_s]
  end

  def t_number(value)
    [:NUMBER, value.to_s]
  end

  def t_string(value)
    [:STRING, value]
  end

  def t_plus
    [:PLUS, '+']
  end

  def t_times
    [:TIMES, '*']
  end

  def t_case
    [:CASE, '{% case']
  end

  def t_when
    [:WHEN, '{% when']
  end

  def t_else
    [:ELSE, '{% else']
  end

  def t_end_case
    [:ENDCASE, '{% endcase %}']
  end

  def t_tag_close
    [:TAGCLOSE, "%}"]
  end

  def t_text(text)
    [:TEXT, text]
  end

  def t_eos
    [false, false]
  end
end
