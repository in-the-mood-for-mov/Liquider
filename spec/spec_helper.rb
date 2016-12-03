require 'liquider'
require 'liquider/erb_compiler'
require 'liquider/rb_compiler'
require 'rspec'
require 'pry'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end

module CapitalizeFilter
  def capitalize(input)
    input.upcase
  end
end

class LiquidContext
  include CapitalizeFilter

  def initialize(context)
    @context = context
  end

  def get_binding
    binding
  end

  def self.wrap(context)
    LiquidContext.new(context).get_binding
  end
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
    def render_erb(compiler)
      compiler.raw("<tag></tag>")
    end

    def render_rb(compiler)
      compiler.raw("<tag></tag>")
    end

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

module IntegrationSpecHelper
  def render_erb(template:, variables:, tags:)
    scanner = Liquider::Scanner.new(Liquider::TextStream.new(template))
    parser = Liquider::Parser.new(tags, scanner)
    compiler = Liquider::ErbCompiler.new
    parser.parse.visit(compiler)
    compiler.output
  end

  def render_rb(template:, variables:, tags:)
    scanner = Liquider::Scanner.new(Liquider::TextStream.new(template))
    parser = Liquider::Parser.new(tags, scanner)
    compiler = Liquider::RbCompiler.new
    parser.parse.visit(compiler)
    compiler.output
  end

  def render_html(template:, variables:, tags:)
    renderer = ERB.new(render_erb(template: template, variables: variables, tags: tags))
    renderer.result(LiquidContext.wrap(variables))
  end
end

module TokenSpecHelper
  def t_ident(value)
    [:IDENT, value.to_s]
  end

  def t_true
    [:TRUE, "true"]
  end

  def t_false
    [:FALSE, "false"]
  end

  def t_number(value)
    [:NUMBER, value.to_s]
  end

  def t_string(value)
    [:STRING, value]
  end

  def t_eq
    [:EQ, "="]
  end

  def t_plus
    [:PLUS, "+"]
  end

  def t_times
    [:TIMES, "*"]
  end

  def t_pipe
    [:PIPE, "|"]
  end

  def t_colon
    [:COLON, ":"]
  end

  def t_dot
    [:DOT, "."]
  end

  def t_comma
    [:COMMA, ","]
  end

  def t_mustache_open
    [:MUSTACHEOPEN, "{{"]
  end

  def t_mustache_close
    [:MUSTACHECLOSE, "}}"]
  end

  def t_if
    [:IF, "{% if"]
  end

  def t_elsif
    [:ELSIF, "{% elsif"]
  end

  def t_else
    [:ELSE, "{% else %}"]
  end

  def t_end_if
    [:ENDIF, "{% endif %}"]
  end

  def t_unless
    [:UNLESS, "{% unless"]
  end

  def t_end_unless
    [:ENDUNLESS, "{% endunless %}"]
  end

  def t_case
    [:CASE, "{% case"]
  end

  def t_when
    [:WHEN, "{% when"]
  end

  def t_end_case
    [:ENDCASE, "{% endcase %}"]
  end

  def t_for
    [:FOR, "{% for"]
  end

  def t_in
    [:IN, "in"]
  end

  def t_reversed
    [:REVERSED, "reversed"]
  end

  def t_end_for
    [:ENDFOR, "{% endfor %}"]
  end

  def t_assign
    [:ASSIGN, "{% assign"]
  end

  def t_capture
    [:CAPTURE, "{% capture"]
  end

  def t_end_capture
    [:ENDCAPTURE, "{% endcapture %}"]
  end

  def t_tag_open(name)
    [:TAGOPEN, "{% #{name}"]
  end

  def t_markup(markup)
    [:MARKUP, markup]
  end

  def t_tag_close
    [:TAGCLOSE, "%}"]
  end

  def t_end_block(name)
    [:ENDBLOCK, "{% #{name} %}"]
  end

  def t_text(text)
    [:TEXT, text]
  end

  def t_eos
    [false, false]
  end
end
