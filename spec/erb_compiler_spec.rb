require 'spec_helper'
require 'liquider'
require 'liquider/erb_compiler'

include Liquider::Ast

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
    let(:target) {
      CallNode.new(StringNode.new("toto"), SymbolNode.new("length"))
    }
    it "doesn't send the symbol to the context" do
      expect(compiler.output).to eq("'toto'.length")
    end
  end

  context IndexNode do
    let(:target) {
      IndexNode.new(SymbolNode.new("toto"), SymbolNode.new("property"))
    }
    it "sends the symbol to the context" do
      expect(compiler.output).to eq("@context['toto'][@context['property']]")
    end
  end

  context SymbolNode do
    let(:target) { SymbolNode.new("number") }
    it "sends the symbol to the context" do
      expect(compiler.output).to eq("@context['number']")
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
end


