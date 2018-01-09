class Activity < ApplicationRecord
  has_many :orders, dependent: :destroy
  has_many :credit_mutations, dependent: :destroy
  belongs_to :price_list
  belongs_to :created_by, class_name: 'User'

  validates :title,       presence: true
  validates :start_time,  presence: true
  validates :end_time,    presence: true
  validates :price_list,  presence: true
  validates :created_by, presence: true
  validates_datetime :end_time, after: :start_time

  validate :validate_closed
  before_update :updatable?

  scope :upcoming, (lambda {
    where('(start_time < ? and end_time > ?) or start_time > ?', Time.zone.now,
          Time.zone.now, Time.zone.now).order(:start_time, :end_time)
  })

  delegate :products, to: :price_list

  def credit_mutations_total
    credit_mutations.map(&:amount).reduce(:+) || 0
  end

  def sold_products
    orders.map(&:order_rows).flatten.map(&:product)
  end

  def revenue
    orders.map(&:order_rows).flatten.map(&:row_total).reduce(:+) || 0
  end

  def bartenders
    orders.map(&:created_by).uniq
  end

  def closed?
    end_time && Time.zone.now >= close_date
  end

  def close_date
    end_time + 1.month
  end

  def validate_closed
    errors.add(:base, 'activity ended longer then a month ago, altering is not allowed anymore') if closed?
  end

  private

  def updatable?
    throw(:abort) if closed?
  end
end
