require 'spec_helper'

describe Liquider::MarkupHelper do
  include TokenSpecHelper
  include Liquider::MarkupHelper

  it "can tokenize liquid source" do
    source = 'liquid'
    text_stream = double('text_stream')
    allow(TextStream).to receive(:new).with(source, mode: :liquid).and_return(text_stream)
    allow(Scanner).to receive(:new).with(text_stream).and_return(t_ident(:x))
    expect(tokenize(source).to_a).to eq(t_ident(:x))
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
end
