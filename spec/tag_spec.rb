require 'spec_helper'

include Liquider
describe Liquider::Tag do
  it 'is not a block' do
    expect(Liquider::Tag.block?).to be(false)
  end
end
