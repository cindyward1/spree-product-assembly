module Spree
  StockLocation.class_eval do
    def count_on_hand(variant)
      if variant.should_track_inventory?
        return stock_item(variant).try(:count_on_hand)
      elsif variant.product.assembly? && variant.is_master?
        lowest_value = Float::INFINITY
        variant.product.parts.each do |part|
          if part.should_track_inventory?
            lowest_value = part.stock_items(:count_on_hand)/variant.product.count_of(part) <
              lowest_value ? part.stock_items(:count_on_hand)/variant.product.count_of(part) :
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
