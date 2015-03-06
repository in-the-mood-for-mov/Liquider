require 'spec_helper'
require 'liquider'
require 'liquider/awesome_printer'

include Liquider::Ast

describe Liquider::AwesomePrinter do
  let(:printer) { Liquider::AwesomePrinter.new(STDOUT) }
  before { target.visit(printer) }

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

    it "prints to stdout" do
    end
  end
end

