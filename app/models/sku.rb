class Sku
  include Mongoid::Document
  include Mongoid::Timestamps

  field :sku, type: String
  field :is_batch, type: Boolean
  field :is_bundle, type: Boolean
  field :has_variants, type: Boolean
  field :quantity_on_shelf, type: Integer
  field :quantity_sellable, type: Integer
  field :quantity_reserved_for_orders, type: Integer
  field :quantity_blocked_by_merchant, type: Integer
  field :warehouses, type: Hash
  field :state, type: String
  field :last_update, type: Time
  field :batches, type: Hash
  field :variants, type: Hash

  index({ sku: 1 }, { unique: true })
  index({ state: 1 })
  index({ is_batch: 1 })
  index({ is_bundle: 1 })
  index({ has_variants: 1 })
  index({ quantity_on_shelf: 1 })
  index({ quantity_sellable: 1 })
  index({ quantity_reserved_for_orders: 1 })
  index({ quantity_blocked_by_merchant: 1 })
  index({ last_update: 1 })

  validates :sku, presence: true, uniqueness: true
  validates :is_batch, inclusion: { in: [true, false] }
  validates :is_bundle, inclusion: { in: [true, false] }
  validates :has_variants, inclusion: { in: [true, false] }
  validates :quantity_on_shelf, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_sellable, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_reserved_for_orders, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_blocked_by_merchant, numericality: { greater_than_or_equal_to: 0 }
  validates :state, presence: true
  validates :last_update, presence: true

  paginates_per 10

  def self.find_by(sku:)
    where(sku: sku).first
  end
end 