require 'spec_helper'
require 'liquid'

Liquid::Template.register_filter(CapitalizeFilter)

include Liquider::Spec

describe Liquider do
  include IntegrationSpecHelper
  let(:liquider_output) {
    render_html(
      template: template,
      variables: variables,
      tags: TAGS,
    )
  }

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
