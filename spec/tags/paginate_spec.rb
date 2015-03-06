require 'spec_helper'

describe Liquider::Tags::Paginate do
  let(:collection) { (1..100).to_a }

  describe 'paginates without a "by" option' do
    let(:template) { <<-TEMPLATE
      {% paginate collection %}
      {% endpaginate %}
    TEMPLATE

    it 'sets current_page' do

    end

    it 'sets current_offset' do
    end

    it 'sets items' do
    end

    it 'sets parts' do
    end

    it 'sets' do
    end
  end
end
