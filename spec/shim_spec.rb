require 'spec_helper'
require 'liquider/shim'

describe Liquider::Shim::Tag do
  def split(body)
    body.split(/(?={{|{%)|(?<=}}|%})/)
  end

  let(:context) {
    Liquid::Context.new
  }

  it 'renders using liquid' do
    expect(Liquider::Shim::Tag.render('if', ' true ', split("the body {% endif %}"), {}, context)).to eq("the body ")
    expect(Liquider::Shim::Tag.render('if', ' false ', split("no body {% endif %}"), {}, context)).to eq("")
    expect(Liquider::Shim::Tag.render('if', ' true ', split("the body {% else %}{% endif %}"), {}, context)).to eq("the body ")
    expect(Liquider::Shim::Tag.render('if', ' false ', split("{% else %} the body {% endif %}"), {}, context)).to eq(" the body ")
  end

  it "parses blocks that haven't been converted" do
    source = StringScanner.new(<<-endofstream)
      first line
      {{ variable }}
      third line
      {% else %}
      fifth line
      {% endif %}
      not reached
    endofstream
    body = Liquid::Tag.body_parser.new('if').parse(source)

    expect(source.rest).to match(/\A\s+not reached\s+\z/)
  end

  it "parses nested blocks that haven't been converted" do
    source = StringScanner.new(<<-endofstream)
      {% if toto %}
        line
      {% endif %}
      {% endif %}
      not reached
    endofstream

    body = Liquid::Tag.body_parser.new('if').parse(source)
    expect(source.rest).to match(/\A\s+not reached\s+\z/)
  end

  describe Liquider::Shim::Parser do
    let(:legacy_tag) { double("Liquid::Tag", block?: false, method_defined?: false) }
    let(:legacy_block) { double("Liquid::Tag", block?: true, method_defined?: false) }
    let(:tags) {
      { legacy_tag: legacy_tag, legacy_block: legacy_block, new_block: Liquider::Shim::Tag }
    }

    it "shims legacy tags" do
      shimmed_tags = {
        legacy_tag: Liquider::Shim::Tag, legacy_block: Liquider::Shim::Block, new_block: Liquider::Shim::Tag
      }
      expect(Liquider::Shim::Parser.shim_tag_classes(tags)).to eq(shimmed_tags)
    end
  end
end

__END__

{% if bool %}
  {% form 'checkout' %}
    {% if false %}
      toto
    {% endif %}
  {% endform %}

{% endif %}

=>
<% if bool %>
  <%= Liquider::Shim::Tag.render("form", "'checkout'", "#{ if false; toto; end } {% endif %}") %>
<% end %>
