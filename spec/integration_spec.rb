require 'spec_helper'
require 'liquid'

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

Liquid::Template.register_filter(CapitalizeFilter)

include Liquider::Spec

describe Liquider do
  let(:scanner) { Liquider::Scanner.new(Liquider::TextStream.new(template)) }
  let(:parser) { Liquider::Parser.new(TAGS, scanner) }
  let(:renderer) {
    compiler = Liquider::ErbCompiler.new
    parser.parse.visit(compiler)
    ERB.new(compiler.output)
  }
  let(:liquider_output) { renderer.result(LiquidContext.wrap(variables)) }

  let(:liquid_template) { Liquid::Template.parse(template) }
  let(:liquid_output) { liquid_template.render(variables) }

  context "basic templates" do
    let(:template) {
      <<-TEMPLATE
        <h1>{{ title | capitalize }}<h1>
        <p>
          This is a pretty slick Liquid page.
          It isn't vulnerable to <%= erb %> injection
        </p>
      TEMPLATE
    }
    let(:variables) { {'title' => 'Page Title'} }

    it "renders the same as Liquid" do
      expect(liquider_output).to eq(liquid_output)
    end
  end

end
