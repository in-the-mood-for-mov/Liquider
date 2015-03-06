require 'spec_helper'

describe Liquider::Tags::Decrement do
  let(:tag) { DecrementTag.new(

  it 'compiles to erb' do
    expect().to eq(

  end
end
