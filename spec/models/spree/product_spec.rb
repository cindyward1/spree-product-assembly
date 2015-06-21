require 'spec_helper'

describe Spree::Product do
  before(:each) do
    @product = FactoryGirl.create(:product, :name => "Foo Bar")
    @master_variant = Spree::Variant.where(is_master: true).find_by_product_id(@product.id)
  end
    
  describe "Spree::Product Assembly" do
    before(:each) do
      @product = create(:product)
      @part1 = create(:product, :can_be_part => true)
      @part2 = create(:product, :can_be_part => true)
      @product.add_part @part1.master, 1
      @product.add_part @part2.master, 4
    end
    
    it "is an assembly" do
      expect(@product).to be_assembly
    end
    

    it "cannot be part" do
      expect(@product).to be_assembly
      @product.can_be_part = true
      @product.valid?
      expect(@product.errors[:can_be_part]).to eq ["assembly can't be part"]
    end

    it 'changing part qty changes count on_hand' do
      @product.set_part_count(@part2.master, 2)
      expect(@product.count_of(@part2.master)).to eq 2
    end
  end
end
