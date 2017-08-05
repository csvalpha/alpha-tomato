require 'rails_helper'

RSpec.describe ProductPrice, type: :model do
  subject(:product_price) { FactoryGirl.build_stubbed(:product_price) }

  describe '#valid' do
    it { expect(product_price).to be_valid }

    context 'when without a amount' do
      subject(:product_price) { FactoryGirl.build_stubbed(:product_price, amount: nil) }

      it { expect(product_price).not_to be_valid }
    end

    context 'when without a list' do
      subject(:product_price) { FactoryGirl.build_stubbed(:product_price, price_list: nil) }

      it { expect(product_price).not_to be_valid }
    end

    context 'when without a product' do
      subject(:product_price) { FactoryGirl.build_stubbed(:product_price, product: nil) }

      it { expect(product_price).not_to be_valid }
    end
  end
end
