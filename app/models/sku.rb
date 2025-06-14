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
  field :state, type: String
  field :last_update, type: DateTime
  field :warehouses, type: Hash
  field :batches, type: Hash
  field :variants, type: Hash

  index({ sku: 1 }, { unique: true })

  validates :sku, presence: true, uniqueness: true
  validates :state, inclusion: { in: %w[active inactive] }
  validates :quantity_on_shelf, :quantity_sellable, :quantity_reserved_for_orders, :quantity_blocked_by_merchant,
            numericality: { greater_than_or_equal_to: 0 }

  def self.find_by(sku:)
    where(sku: sku).first
  end
end 