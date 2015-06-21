module Spree
  StockItem.class_eval do
    def total_on_hand
      if self.variant.should_track_inventory? && (!self.variant.product.assembly? ||
        !self.variant.is_master? || self.variant.track_inventory)
        return self.try(:count_on_hand)
      elsif self.variant.product.assembly? && self.variant.is_master?
        lowest_value = Float::INFINITY
        self.variant.product.parts.each do |part|
          if part.should_track_inventory?
            part_stock_item = Spree::StockItem.where(variant_id: part.id,
              stock_location_id: self.stock_location_id).first
            lowest_value = part_stock_item[:count_on_hand]/self.variant.product.count_of(part) <
              lowest_value ? part_stock_item[:count_on_hand]/self.variant.product.count_of(part) :
              lowest_value
          end
        end
        return lowest_value
      else
        Float::INFINITY
      end
    end
  end
end
