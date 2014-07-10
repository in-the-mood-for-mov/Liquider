require 'spec_helper'

Template = <<-TEMPLATE
  <h1>{{ title | capitalize }}<h1>
  <p>
    This is a pretty slick Liquid page.
    It isn't vulnerable to <%= erb %> injection
  </p>
  {% tag 'tags', 'still', 'work' %}
  {% tag 'tags', 'still', 'work' %}
  {% tag 'tags', 'still', 'work' %}
  {% block nested.variable %}
    variables can be resolved
    Uh oh!
  {% endblock %}
TEMPLATE

include Liquider::Spec

describe Liquider do
  it "can render erb templates" do
    scanner = Liquider::Scanner.new(Liquider::TextStream.new(Template))
    parser = Liquider::Parser.new(TAGS, scanner)
  end
end
