require 'spec_helper'

include Liquider::Ast

describe Liquider::Ast do
  context LitteralNode do
    node_class = Node.new_type(:type, modules: [LitteralNode])

    it 'yields with on_litteral' do
      subject = node_class.new
      must_be_called = spy
      subject.on_litteral {
        must_be_called.call
      }
      expect(must_be_called).to have_recieved(:call)
    end
  end
end
