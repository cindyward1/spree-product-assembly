FactoryGirl.define do
  factory :stock_location_with_parts, class: Spree::StockLocation do
    name 'NY Warehouse'
    address1 '1600 Pennsylvania Ave NW'
    city 'Washington'
    zipcode '20500'
    phone '(202) 456-1111'
    active true
    backorderable_default true

    country  { |stock_location| Spree::Country.first || stock_location.association(:country) }
    state do |stock_location|
      stock_location.country.states.first || stock_location.association(:state, :country => stock_location.country)
    end

    after(:create) do |stock_location, evaluator|
      existing_product = Spree::Product.where(id: 1).first
      if existing_product.nil?
        product_with_parts = create(:product)
        product_with_parts.master.track_inventory = false
        parts = (1..2).map { create(:variant) }
        product_with_parts.parts << parts
        product_with_parts.parts.each do |part|
          part.track_inventory = true
        end
      else
        product_with_parts = existing_product
      end

      stock_location.stock_items.where(:variant_id => product_with_parts.parts.first.id).first.adjust_count_on_hand(10)
      stock_location.stock_items.where(:variant_id => product_with_parts.parts.last.id).first.adjust_count_on_hand(20)
    end
  end
end
