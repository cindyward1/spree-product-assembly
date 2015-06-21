require 'spec_helper'

module Spree
  module Stock
    describe InventoryUnitBuilder, :type => :model do
      context 'product is an assembly' do
        let!(:order) { create(:order_with_line_items) }
        let!(:parts) { (1..3).map { create(:variant) } }
        let!(:bundle_variant) { order.variants.first }
        let!(:bundle) { bundle_variant.product }
        before do
          bundle.parts << parts
        end

        subject { InventoryUnitBuilder.new(order) }
        let(:bundle_item_quantity) { order.find_line_item_by_variant(bundle_variant).quantity }

        describe "#units" do
          it "returns an inventory unit for each part of each quantity for the order's line items" do
            units = subject.units
            line_item = order.line_items.first
            expect(units.count).to eq line_item.parts.size
            expect(units[0].line_item.quantity).to eq order.line_items.first.quantity
            expect(units[0].line_item.quantity).to eq bundle_item_quantity

            expect(units.map(&:variant)).to match_array line_item.parts
          end

          it "builds the inventory units as pending" do
            expect(subject.units.map(&:pending).uniq).to eq [true]
          end

          it "associates the inventory units to the order" do
            expect(subject.units.map(&:order).uniq).to eq [order]
          end
        end
      end
    end
  end
end
