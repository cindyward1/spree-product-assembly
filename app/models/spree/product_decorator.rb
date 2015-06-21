Spree::Product.class_eval do
  delegate_belongs_to :master, :track_inventory, :backorderable

  has_and_belongs_to_many  :parts, :class_name => "Spree::Variant",
        :join_table => "spree_assemblies_parts",
        :foreign_key => "assembly_id", :association_foreign_key => "part_id"

  has_many :assemblies_parts, :class_name => "Spree::AssembliesPart",
    :foreign_key => "assembly_id"

  scope :individual_saled, -> { where(individual_sale: true) }

  scope :search_can_be_part, ->(query){ not_deleted.available.joins(:master)
    .where(arel_table["name"].matches("%#{query}%").or(Spree::Variant.arel_table["sku"].matches("%#{query}%")))
    .where(can_be_part: true)
    .limit(30)
  }

  validate :assembly_cannot_be_part, :if => :assembly?

  def add_part(variant, count = 1)
    set_part_count(variant, count_of(variant) + count)
  end

  def remove_part(variant)
    set_part_count(variant, 0)
  end

  def set_part_count(variant, count)
    ap = assemblies_part(variant)
    if count > 0
      ap.count = count
      ap.save
    else
      ap.destroy
    end
    reload
  end

  def assembly?
    parts.present?
  end

  def count_of(variant)
    ap = assemblies_part(variant)
    # This checks persisted because the default count is 1
    ap.persisted? ? ap.count : 0
  end

  def assembly_cannot_be_part
    errors.add(:can_be_part, Spree.t(:assembly_cannot_be_part)) if can_be_part
  end

  def any_variants_not_track_inventory?
    if variants_including_master.loaded?
      variants_including_master.any? { |v| !v.should_track_inventory? }
    else
      !Spree::Config.track_inventory_levels || !self.assembly? &&
        variants_including_master.where(track_inventory: false).any? ||
        self.assembly? && variants.where(track_inventory: false).any?
    end
  end

  def total_on_hand
    if any_variants_not_track_inventory?
      return Float::INFINITY
    elsif self.assembly?
      lowest_value = Float::INFINITY
      self.parts.each do |part|
        if part.should_track_inventory?
          lowest_value =
            part.stock_items.sum(:count_on_hand)/self.count_of(part) < lowest_value ?
            part.stock_items.sum(:count_on_hand)/self.count_of(part) : lowest_value
        end
      end
      return lowest_value
    else
      return stock_items.sum(:count_on_hand)
    end
  end

  private

  def assemblies_part(variant)
    Spree::AssembliesPart.get(self.id, variant.id)
  end
end
