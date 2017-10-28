class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:banana_oauth2]
  has_many :orders, dependent: :destroy
  has_many :credit_mutations, dependent: :destroy
  validates :name, presence: true

  def credit
    credit = credit_mutations.sum(:amount)
    orders.each do |order|
      credit -= order.order_total
    end
    credit
  end

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.name = auth[:info][:name]
    end
  end
end
