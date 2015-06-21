module Spree
  module Stock
    Quantifier.class_eval do
      def initialize(variant)
        @variant = variant
        if @variant.product.assembly? && @variant.is_master && !@variant.track_inventory
          @stock_items = []
          @variant.product.parts.each.map do |part|
            @stock_items << Spree::StockItem.joins(:stock_location).where(:variant_id => part.id, 
              Spree::StockLocation.table_name => { :active => true })
          end
          @stock_items.flatten!
        else
          @stock_items = Spree::StockItem.joins(:stock_location).where(:variant_id => @variant.id, 
            Spree::StockLocation.table_name => { :active => true })
        end
      end

      def total_on_hand
        if @variant.should_track_inventory? && (!@variant.product.assembly? || 
          !@variant.is_master || @variant.track_inventory)
          return stock_items.sum(:count_on_hand)
        elsif @variant.product.assembly? && @variant.is_master?
          lowest_value = Float::INFINITY
          @variant.product.parts.each do |part|
            if part.should_track_inventory?
              lowest_value = part.stock_items.joins(:stock_location).where(:variant_id => part.id,
                Spree::StockLocation.table_name =>
                  { :active => true }).sum(:count_on_hand)/@variant.product.count_of(part) < lowest_value ?
                part.stock_items.joins(:stock_location).where(:variant_id => part.id,
                Spree::StockLocation.table_name =>
                  { :active => true }).sum(:count_on_hand)/@variant.product.count_of(part) :
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
end
             