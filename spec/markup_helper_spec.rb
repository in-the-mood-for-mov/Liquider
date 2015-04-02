require 'spec_helper'

include Liquider::Ast
describe Liquider::MarkupHelper do
  include TokenSpecHelper
  include Liquider::MarkupHelper

  it "can tokenize liquid source" do
    source = 'liquid'
    expect(tokenize(source).to_a).to eq([t_text('liquid'), t_eos])
  end

  it "can split a simple token stream on a keyword" do
    tokens = [t_string('foo'), t_ident(:with), t_string('bar')]
    expect(split_on_keyword(:with, tokens)).to eq([[t_string('foo')], [t_string('bar')]])
  end

  it "can split a token stream with multiple occurence of the keyword" do
    tokens = [
      t_ident(:a), t_plus, t_ident(:b),
      t_ident(:x), t_number(3),
      t_ident(:x), t_ident(:c), t_times, t_ident(:d),
    ]
    expect(split_on_keyword(:x, tokens)).to eq([
      [t_ident(:a), t_plus, t_ident(:b)],
      [t_number(3)],
      [t_ident(:c), t_times, t_ident(:d)],
    ])
  end

  it "can parse expressions" do
    ast = Liquider::Ast::BinOpNode.new(
      :+,
      NumberNode.new(5),
      NumberNode.new(4),
    )
    expect(parse_expression('5 + 4')).to eq(ast)
  end

  it "can parse arguments" do
    ast = ArgListNode.new(
      [
        StringNode.new("titi"),
        StringNode.new("toto"),
      ],
      [
        OptionPairNode.new("tu", StringNode.new("tu"))
      ],
    )
    expect(parse_arguments('"titi", "toto", tu: "tu"')).to eq(ast)
  end
end
