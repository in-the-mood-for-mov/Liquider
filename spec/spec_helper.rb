require 'liquider'
require 'liquider/erb_compiler'
require 'rspec'
require 'pry'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end

module Liquider::Spec
  class TestBlock < Liquider::Block
    class << self
      def parse_markup(source)
        :markup
      end
    end
  end

  class TestTag < Liquider::Tag
    class << self
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

  def t_keyword(value)
    [:KEYWORD, "#{value}:"]
  end

  def t_number(value)
    [:NUMBER, value.to_s]
  end

  def t_string(value)
    [:STRING, value]
  end

  def t_eq
    [:EQ, '=']
  end

  def t_plus
    [:PLUS, '+']
  end

  def t_times
    [:TIMES, '*']
  end

  def t_dot
    [:DOT, '.']
  end

  def t_comma
    [:COMMA, ',']
  end

  def t_mustache_open
    [:MUSTACHEOPEN, '{{']
  end

  def t_mustache_close
    [:MUSTACHECLOSE, '}}']
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

  def t_for
    [:FOR, '{% for']
  end

  def t_in
    [:IN, 'in']
  end

  def t_reversed
    [:REVERSED, 'reversed']
  end

  def t_end_for
    [:ENDFOR, '{% endfor %}']
  end

  def t_assign
    [:ASSIGN, '{% assign']
  end

  def t_capture
    [:CAPTURE, '{% capture']
  end

  def t_end_capture
    [:ENDCAPTURE, '{% endcapture %}']
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
