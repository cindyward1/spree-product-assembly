require 'spec_helper'

shared_examples_for 'unlimited supply' do
  it 'can_supply? any amount' do
    expect(subject.can_supply?(1)).to be true
    expect(subject.can_supply?(101)).to be true
    expect(subject.can_supply?(100_001)).to be true
  end
end

def configure_spree_preferences
  config = Rails.application.config.spree.preferences
  yield(config) if block_given?
end

module Spree
  module Stock
    describe Quantifier, :type => :model do

      context "bundle parts stock for a single part" do
        let!(:stock_location) { create :stock_location_with_parts }
        let!(:stock_item_first) { stock_location.stock_items.includes(:variant).where(spree_variants: { is_master: false }).first }
        let!(:product) { stock_location.stock_items.first.variant.product }
        let!(:variant_part_first) { product.parts.first }
        let!(:master_variant) { product.master }
        
        context 'with a single stock location/item' do
          before do
            master_variant.track_inventory = false
          end

          subject { described_class.new(variant_part_first) }

          specify { expect(subject.stock_items).to eq [stock_item_first] }

          it 'total_on_hand should match stock_item' do
            expect(subject.total_on_hand).to eq(stock_item_first.count_on_hand)
            expect(subject.total_on_hand).to eq 10
          end

          context 'when track_inventory_levels is false' do
            before { configure_spree_preferences { |config| config.track_inventory_levels = false } }
            specify { expect(subject.total_on_hand).to eq Float::INFINITY }
            it_should_behave_like 'unlimited supply'
          end

          context 'when inventory tracking is off' do
            before { variant_part_first.track_inventory = false }
            specify { expect(subject.total_on_hand).to eq Float::INFINITY }
            it_should_behave_like 'unlimited supply'
          end

          context 'when stock item allows backordering' do
            specify { expect(subject.backorderable?).to be true }
            it_should_behave_like 'unlimited supply'
          end

          context 'when stock item prevents backordering' do
            before { stock_item_first.update_attributes(backorderable: false) }
            specify { expect(subject.backorderable?).to be false }

            it 'can_supply? only upto total_on_hand' do
              expect(subject.can_supply?(1)).to be true
              expect(subject.can_supply?(10)).to be true
              expect(subject.can_supply?(11)).to be false
            end
          end
        end

        context 'with multiple stock locations/items' do
          let!(:stock_location_2) { create :stock_location_with_parts }
          let!(:stock_location_3) { create :stock_location_with_parts, active: false }

          before do
            master_variant.track_inventory = false
            stock_location.stock_items.where(variant_id: variant_part_first.id).update_all(count_on_hand: 10, backorderable: true)
            stock_location_2.stock_items.where(variant_id: variant_part_first.id).update_all(count_on_hand: 5, backorderable: true)
            stock_location_3.stock_items.where(variant_id: variant_part_first.id).update_all(count_on_hand: 5, backorderable: false)
          end

          let!(:stock_item_first_2) { stock_location_2.stock_items.includes(:variant).where(spree_variants: { is_master: false }).first }
          let!(:stock_item_first_3) { stock_location_3.stock_items.includes(:variant).where(spree_variants: { is_master: false }).first }

          subject { described_class.new(variant_part_first) }

          specify { expect(subject.stock_items).to eq [stock_item_first, stock_item_first_2] }

          it 'total_on_hand should total all active stock_items' do
            expect(subject.total_on_hand).to eq(stock_item_first.count_on_hand + stock_item_first_2.count_on_hand)
            expect(subject.total_on_hand).to eq 15
          end

          context 'when track_inventory_levels is false' do
            before { configure_spree_preferences { |config| config.track_inventory_levels = false } }
            specify { expect(subject.total_on_hand).to eq Float::INFINITY }
            it_should_behave_like 'unlimited supply'
          end

           context 'when inventory tracking is off' do
            before { variant_part_first.track_inventory = false }
            specify { expect(subject.total_on_hand).to eq Float::INFINITY }
            it_should_behave_like 'unlimited supply'
          end

          context 'when any stock item allows backordering' do
            specify { expect(subject.backorderable?).to be true }
            it_should_behave_like 'unlimited supply'
          end

          context 'when all stock items prevent backordering' do
            before do
              stock_location.stock_items.where(variant_id: variant_part_first.id).update_all(count_on_hand: 10, backorderable: false)
              stock_location_2.stock_items.where(variant_id: variant_part_first.id).update_all(count_on_hand: 5, backorderable: false)
              stock_location_3.stock_items.where(variant_id: variant_part_first.id).update_all(count_on_hand: 5, backorderable: false)
            end

            specify { expect(subject.backorderable?).to be false }

            it 'can_supply? only upto total_on_hand' do
              expect(subject.can_supply?(1)).to be true
              expect(subject.can_supply?(15)).to be true
              expect(subject.can_supply?(16)).to be false
            end
          end
        end
      end

      context "bundle parts stock for an assembly of 2 parts, quantity 1 of each part" do
        let!(:stock_location) { create :stock_location_with_parts }
        let!(:stock_item_first) { stock_location.stock_items.includes(:variant).where(spree_variants: { is_master: false }).first }
        let!(:stock_item_last) { stock_location.stock_items.includes(:variant).where(spree_variants: { is_master: false }).last }
        let!(:product) { stock_location.stock_items.first.variant.product }
        let!(:variant_part_first) { product.parts.first }
        let!(:variant_part_last) { product.parts.last }
        let!(:master_variant) { product.master }

        context 'with multiple stock locations/items' do
          let!(:stock_location_2) { create :stock_location_with_parts }
          let!(:stock_location_3) { create :stock_location_with_parts, active: false }
         
          before do
            master_variant.track_inventory = false
            stock_location.stock_items.where(variant_id: variant_part_first.id).update_all(count_on_hand: 10, backorderable: true)
            stock_location.stock_items.where(variant_id: variant_part_last.id).update_all(count_on_hand: 20, backorderable: true)
            stock_location_2.stock_items.where(variant_id: variant_part_first.id).update_all(count_on_hand: 5, backorderable: true)
            stock_location_2.stock_items.where(variant_id: variant_part_last.id).update_all(count_on_hand: 10, backorderable: true)
            stock_location_3.stock_items.where(variant_id: variant_part_first.id).update_all(count_on_hand: 5, backorderable: false)
            stock_location_3.stock_items.where(variant_id: variant_part_last.id).update_all(count_on_hand: 10, backorderable: false)
          end 

          let!(:stock_item_first_2) { stock_location_2.stock_items.includes(:variant).where(spree_variants: { is_master: false }).first }
          let!(:stock_item_last_2) { stock_location_2.stock_items.includes(:variant).where(spree_variants: { is_master: false }).last }
          let!(:stock_item_first_3) { stock_location_3.stock_items.includes(:variant).where(spree_variants: { is_master: false }).first }
          let!(:stock_item_last_3) { stock_location_3.stock_items.includes(:variant).where(spree_variants: { is_master: false }).last }


          subject { described_class.new(master_variant) }

          specify { expect(subject.stock_items).to eq [stock_item_first, stock_item_first_2, stock_item_last, stock_item_last_2] }

          context 'total_on_hand should match total/count of stock item with lower quantity in active locations' do
            specify { expect(subject.total_on_hand).to eq(subject.stock_items[0].total_on_hand + subject.stock_items[1].total_on_hand) }
            specify { expect(subject.total_on_hand).to eq(subject.stock_items[0].count_on_hand + subject.stock_items[1].count_on_hand) }
          end

          context 'when track_inventory_levels is false' do
            before { configure_spree_preferences { |config| config.track_inventory_levels = false } }
            specify { expect(subject.total_on_hand).to eq Float::INFINITY }
            it_should_behave_like 'unlimited supply'
          end

          context 'when inventory tracking is off for first variant' do
            before { subject.instance_variable_get(:@variant).product.parts.first.track_inventory = false }
            specify { expect(subject.total_on_hand).to eq 30 }
          end

          context 'when stock item allows backordering' do
            specify { expect(subject.backorderable?).to be true }
            it_should_behave_like 'unlimited supply'
          end

          context 'when stock item prevents backordering' do
            before do
              stock_item_first.update_attributes(backorderable: false)
              stock_item_last.update_attributes(backorderable: false)
              stock_item_first_2.update_attributes(backorderable: false)
              stock_item_last_2.update_attributes(backorderable: false)
              stock_item_first_3.update_attributes(backorderable: false)
              stock_item_last_3.update_attributes(backorderable: false)
            end
            specify { expect(subject.backorderable?).to be false }

            it 'can_supply? only upto total_on_hand' do
              expect(subject.can_supply?(1)).to be true
              expect(subject.can_supply?(15)).to be true
              expect(subject.can_supply?(16)).to be false
            end
          end
        end
      end
    end
  end
end
