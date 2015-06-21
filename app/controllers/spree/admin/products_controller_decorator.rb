module Spree
  module Admin
    ProductsController.class_eval do
      def stock
        @variants = @product.variants.includes(*variant_stock_includes)
        @variants = @product.parts.includes(*variant_stock_includes) if @variants.empty? && !@product.master.track_inventory?
        @variants = [@product.master] if @variants.empty?
        @stock_locations = StockLocation.accessible_by(current_ability, :read)
        if @stock_locations.empty?
          flash[:error] = Spree.t(:stock_management_requires_a_stock_location)
          redirect_to admin_stock_locations_path
        end
      end
    end
  end
end