require 'erb'
require 'pry'

puts ERB.new(DATA.read).result(binding)

class Form
  include Liquider::ErbCompiler::Ast
  def visit(compiler)

  end

  def to_erb
    ContextStackNode.new(
      DocumentNode.new(
        CaptureNode.new("form", TextNode.new("the actual form")),
        HtmlBlockNode.new("form",
          [],
          MustacheNode.new(LocalFetchNode.new("form")),
        )
      )
    )
  end
end

__END__
<% capture = lambda{ |&block| begin; _newout = ""; _oldout, _erbout = _erbout, _newout; block.call; ensure; _erbout = _oldout;  _newout; end; } %>
<% toto = capture.call do %>
  something
  <%= 'something else' %>
<% end %>
<%= toto %>
