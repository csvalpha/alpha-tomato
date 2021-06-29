class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:banana_oauth2]
  has_many :orders, dependent: :destroy
  has_many :order_rows, through: :orders, dependent: :destroy
  has_many :credit_mutations, dependent: :destroy
  has_many :activities, dependent: :destroy, foreign_key: 'created_by_id', inverse_of: :created_by

  has_many :roles_users, class_name: 'RolesUsers', dependent: :destroy, inverse_of: :user
  has_many :roles, through: :roles_users

  validates :name, presence: true
  validates :uid, uniqueness: true, allow_blank: true
  validate :no_deactivation_when_nonzero_credit

  scope :in_banana, (-> { where(provider: 'banana_oauth2') })
  scope :manual, (-> { where(provider: nil) })
  scope :active, (-> { where(deactivated: false) })
  scope :inactive, (-> { where(deactivated: true) })
  scope :treasurer, (-> { joins(:roles).merge(Role.treasurer) })

  def credit
    credit_mutations.sum('amount') - order_rows.sum('product_count * price_per_product')
  end

  def avatar_thumb_or_default_url
    return '/images/avatar_thumb_default.png' unless avatar_thumb_url

    "#{Rails.application.config.x.banana_api_url}#{avatar_thumb_url}"
  end

  def age
    return nil unless birthday

    age = Time.zone.now.year - birthday.year
    age -= 1 if Time.zone.now < birthday + age.years
    age
  end

  def minor
    return false unless age

    age < 18
  end

  def treasurer?
    @treasurer ||= roles.where(role_type: :treasurer).any?
  end

  def main_bartender?
    @main_bartender ||= roles.where(role_type: :main_bartender).any?
  end

  def update_role(groups)
    roles_to_have = Role.where(group_uid: groups)
    roles_users_to_have = roles_to_have.map { |role| RolesUsers.find_or_create_by(role: role, user: self) }

    roles_users_not_to_have = roles_users - roles_users_to_have
    roles_users_not_to_have.map(&:destroy)
  end

  def archive!
    attributes.each_key do |attribute|
      self[attribute] = nil unless %w[deleted_at updated_at created_at provider id uid].include? attribute
    end
    self.name = "Gearchiveerde gebruiker #{id}"
    self.deactivated = true
    save & versions.destroy_all
  end

  # TODO: Spec this method
  # :nocov:
  def self.from_omniauth(auth)
    user = where(provider: auth.provider, uid: auth.uid).first_or_create do |u|
      u.name = auth[:info][:name]
    end
    user.update_role(auth[:info][:groups])
    user
  end

  # :nocov:

  def self.full_name_from_attributes(first_name, last_name_prefix, last_name)
    [first_name, last_name_prefix, last_name].reject(&:blank?).join(' ')
  end

  def self.calculate_credits
    credits = User.all.left_outer_joins(:credit_mutations).group(:id).sum('amount')
    costs = User.calculate_spendings

    credits.each_with_object({}) { |(id, credit), h| h[id] = credit - costs.fetch(id, 0) }
  end

  def self.calculate_spendings(from: '01-01-1970', to: Time.zone.now)
    User.all.joins(:order_rows)
        .where('orders.created_at >= ? AND orders.created_at < ?', from, to)
        .group(:id).sum('product_count * price_per_product')
  end

  private

  def no_deactivation_when_nonzero_credit
    return unless deactivated && credit != 0

    errors.add(:deactivated, 'cannot deactivate when credit is non zero')
  end
end
