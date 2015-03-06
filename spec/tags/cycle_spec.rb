require 'spec_helper'

describe Liquider::Tags::Cycle do
  it 'renders using only positional arguments' do
    string = "{% cycle 'toto', titi, 'tutu' %}"

    stream = Liquider::TextStream.new(string)
    scanner = Liquider::Scanner.new(stream)
    parser = Liquider::Parser.new({'cycle' => Liquider::Tags::Cycle}, scanner)

    # binding.pry
  end
end
