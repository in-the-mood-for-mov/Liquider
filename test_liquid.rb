require 'pry'
require 'pry-debugger'
require 'liquid'


numbers = (1..100).to_a

Liquid::Template.error_mode = :strict
template = Liquid::Template.parse(<<-TEMPLATE)
{% assign toto = 3 %}
{{ toto }}
3
TEMPLATE

puts template.render('numbers' => numbers)
