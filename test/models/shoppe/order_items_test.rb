require 'test_helper'

module Shoppe
  class OrderItemsTest < ActiveSupport::TestCase
    
    setup do
      @order = create(:order)
      @product = create(:yealink_t22p, :weight => 0.5, :initial_stock => 10)
      @item = @order.order_items.create!(:quantity => 2, :ordered_item => @product)
    end
    
    test "new item can be added to order" do
      product2 = create(:snom_870, :initial_stock => 10)
      assert new_item = @order.order_items.add_item(product2, 1)
      assert_equal true, new_item.is_a?(OrderItem)
      assert_equal product2, new_item.ordered_item
      assert_equal 1, new_item.quantity
    end
    
    test "item can be removed from order" do
      assert @item.remove
      assert_equal true, @item.destroyed?
    end
    
    test "item quantity can be increased" do
      assert_nothing_raised { @item.increase!(1) }
      assert_equal 3, @item.quantity
      # ensure we can't go over quantity available
      assert_raise(Errors::NotEnoughStock) { @item.increase!(100) }
    end
    
    test "item quantity can be decreased" do
      assert_nothing_raised { @item.decrease!(1) }
      assert_equal 1, @item.quantity
      # ensure item is removed when decreasd to 0
      assert_nothing_raised { @item.decrease!(1) }
      assert_equal 0, @item.quantity
      assert_equal true, @item.destroyed?
    end
    
    test "the total weight is returned" do
      assert_equal BigDecimal(0.5, 8), @item.weight
      assert_equal BigDecimal(1), @item.total_weight
    end
    
    test "financials" do
      assert_equal BigDecimal(100), @item.unit_price
      assert_equal BigDecimal(50), @item.unit_cost_price
      assert_equal BigDecimal(20), @item.tax_rate
      assert_equal BigDecimal(40), @item.tax_amount
      assert_equal BigDecimal(100), @item.total_cost
      assert_equal BigDecimal(200), @item.sub_total
      assert_equal BigDecimal(240), @item.total
    end
    
    test "stock allocation" do
      assert_equal 2, @item.unallocated_stock
      assert_equal 0, @item.allocated_stock
      assert_equal true, @item.in_stock?
    end
    
    test "stock level validation" do
      # check that we have some in stock and validate returns false
      assert_equal 2, @item.quantity
      assert_equal false, @item.validate_stock_levels
      # lose some stock
      @item.ordered_item.stock_level_adjustments.create!(:adjustment => (0-@item.ordered_item.stock) + 1, :description => "Only one left")
      # check that validate returns itself and the quantity has been updated
      assert_equal @item, @item.validate_stock_levels
      assert_equal 1, @item.quantity
    end
    
    test "stock allocations and validations don't apply to products without stock control" do
      product = create(:software_product)
      assert_equal false, product.stock_control?
      assert_equal 0, product.stock
      item = nil
      assert_nothing_raised { item = @order.order_items.add_item(product, 1) }
      assert_equal 0, item.allocated_stock
      assert_equal 1, item.unallocated_stock
      assert_equal true, item.in_stock?
      assert_equal false, item.validate_stock_levels
    end
    
  end
end