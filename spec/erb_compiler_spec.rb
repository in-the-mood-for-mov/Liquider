require 'spec_helper'
require 'liquider'
require 'liquider/erb_compiler'

include Liquider::Ast
include Liquider::ErbCompiler::Ast

describe Liquider::ErbCompiler do
  let(:compiler) { Liquider::ErbCompiler.new }
  before { target.visit(compiler) }

  context StringNode do
    let(:target) { StringNode.new("hello y'all") }
    it "escapes the strings" do
      expect(compiler.output).to eq("'hello y\\'all'")
    end
  end

  context NumberNode do
    let(:target) { NumberNode.new(123.333) }
    it "outputs the number" do
      expect(compiler.output).to eq("123.333")
    end
  end

  context TextNode do
    let(:target) { TextNode.new("<%= toto %>") }
    it "escapes the erb out of it" do
      expect(compiler.output).to eq("<%%= toto %>")
    end
  end

  context MustacheNode do
    let(:target) {
      MustacheNode.new(StringNode.new("foo"))
    }
    it "wraps it's expression into an erb output node" do
      expect(compiler.output).to eq("<%= 'foo' %>")
    end
  end

  context BinOpNode do
    let(:target) {
      BinOpNode.new(
        StringNode.new("foo"),
        StringNode.new("bar"),
        :+
      )
    }
    it "adds spaces for sanity" do
      expect(compiler.output).to eq("'foo' + 'bar'")
    end
  end

  context CallNode do
    context 'litteral' do
      let(:target) {
        CallNode.new(StringNode.new("toto"), SymbolNode.new("length"))
      }
      it "doesn't send the symbol to the context" do
        skip
        expect(compiler.output).to eq("'toto'.length")
      end
    end

    context 'symbol' do
      let(:target) {
        CallNode.new(
          CallNode.new(SymbolNode.new("toto"), SymbolNode.new("titi")),
          SymbolNode.new("tata")
        )
      }

      it 'delegates the call to the context' do
        expect(compiler.output).to eq("@context['toto.titi.tata']")
      end
    end
  end

  context IndexNode do
    let(:target) {
      IndexNode.new(SymbolNode.new("toto"), SymbolNode.new("property"))
    }
    it "sends the symbol to the context" do
      expect(compiler.output).to eq("@context['toto[property]']")
    end
  end

  context SymbolNode do
    let(:target) { SymbolNode.new("number") }
    it "sends the symbol to the context" do
      expect(compiler.output).to eq("@context['number']")
    end
  end

  context AssignNode do
    context "simple" do
      let(:target) {
        AssignNode.new(SymbolNode.new("toto"), StringNode.new("titi"))
      }

      it 'assigns a litteral' do
        expect(compiler.output).to eq("@context['toto'] = 'titi'")
      end
    end

    context "with filters" do
      let(:target) {
        AssignNode.new(SymbolNode.new('toto'),
          FilterNode.new(
            "filter1",
            ArgListNode.new([
              SymbolNode.new("identifier")
            ], [])
          )
        )
      }

      it 'assigns to the context correctly' do
        expect(compiler.output).to eq("@context['toto'] = filter1(@context['identifier'])")
      end
    end
  end

  context FilterNode do
    let(:target) {
      FilterNode.new(
        "filter2",
        ArgListNode.new([
          FilterNode.new(
            "filter1",
            ArgListNode.new([
              SymbolNode.new("identifier")
            ], [])
          )], []
        )
      )
    }
    it 'unwraps filters correctly' do
      expect(compiler.output).to eq("filter2(filter1(@context['identifier']))")
    end
  end

  context ArgListNode do
    let(:target) {
      ArgListNode.new([
        StringNode.new('arg1'),
        SymbolNode.new('variable')
      ], [
        OptionPairNode.new(
          'key',
          StringNode.new('value')
        ),
        OptionPairNode.new(
          'other_key',
          SymbolNode.new('other_variable')
        )
      ])
    }

    it 'correctly outputs positionals and optionals' do
      expect(compiler.output).to eq("'arg1', @context['variable'], {'key' => 'value', 'other_key' => @context['other_variable']}")
    end
  end

  context ParenthesisedNode do
    let(:target) {
      ParenthesisedNode.new(
        BinOpNode.new(
          ParenthesisedNode.new(BinOpNode.new(NumberNode.new(1), NumberNode.new(3), :+)),
          BinOpNode.new(NumberNode.new(4), NumberNode.new(5), :*),
          :/
        )
      )
    }
    it "can be nested" do
      expect(compiler.output).to eq("((1 + 3) / 4 * 5)")
    end
  end

  context DocumentNode do
    let(:target) {
      DocumentNode.new([
        MustacheNode.new(
          BinOpNode.new(
            BinOpNode.new(
              SymbolNode.new('foo'),
              BinOpNode.new(
                StringNode.new('bar'),
                SymbolNode.new('baz'),
                :*,
              ),
              :+,
            ),
            NumberNode.new(40),
            :<,
          ),
        ),
        TextNode.new("this is sparta")
      ])
    }

    it "compiles the document" do
      expect(compiler.output).to eq("<%= @context['foo'] + 'bar' * @context['baz'] < 40 %>this is sparta")
    end
  end

  context HtmlTagNode do
    let(:target) {
      HtmlTagNode.new(:input, [OptionPairNode.new("type", SymbolNode.new("text"))])
    }
    it 'renders tags with attributes' do
      expect(compiler.output).to eq('<input type="<%= @context[\'text\'] %>"/>')
    end
  end

  context HtmlBlockNode do
    let(:target) {
      HtmlBlockNode.new(
        :div,
        [OptionPairNode.new("class", StringNode.new("content"))],
        TextNode.new("a body")
      )
    }
    it 'renders blocks with attributes' do
      expect(compiler.output).to eq("<div class='content'>a body</div>")
    end
  end

  context CaptureNode do
    let(:target) {
      CaptureNode.new("toto", HtmlTagNode.new(:div, []))
    }
    it 'captures the body of the div' do
      expect(compiler.output).to eq("<% toto = capture do %><div/><% end %>")
    end
  end

  context LocalAssignNode do
    let(:target) {
      LocalAssignNode.new("toto", StringNode.new("titi"))
    }
    it 'assigns the variable to the local context' do
      expect(compiler.output).to eq("<% toto = 'titi' %>")
    end
  end

  context LocalFetchNode do
    let(:target) {
      MustacheNode.new(LocalFetchNode.new("toto"))
    }
    it 'renders correctly' do
      expect(compiler.output).to eq("<%= toto %>")
    end
  end

  context ContextStackNode do
    let(:target) {
      ContextStackNode.new(TextNode.new("text"))
    }
    it 'stacks context' do
      expect(compiler.output).to eq("<% @context.stack do %>text<% end %>")
    end
  end
end

