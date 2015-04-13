require "spec_helper"

describe CycleTag do
  include IntegrationSpecHelper

  let(:template) { '{% cycle "titi", "toto", "tutu" %}-' * 4 }

  it "renders html" do
    result = render_html(template: template, variables: {}, tags: { "cycle" => CycleTag })
    expect(result).to eq("titi-toto-tutu-titi-")
  end

end
