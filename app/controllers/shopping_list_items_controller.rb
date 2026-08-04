class ShoppingListItemsController < ApplicationController
  before_action :set_item, only: %i[update destroy]


  def index
    @items = Current.user.shopping_list_items.order(:created_at)
  end

  def create
    item = Current.user.shopping_list_items.new(content: params[:content])

    if item.save
      redirect_to shopping_list_items_path, notice: "Lades till."
    else
      redirect_to shopping_list_items_path, alert: "Ett fel uppstod. Försök igen."
    end
  end

  def update
    @item.update!(checked: params[:checked])

    head :no_content
  end

  def destroy
    @item.destroy

    redirect_to shopping_list_items_path, notice: "Togs bort."
  end

  def destroy_all
    Current.user.shopping_list_items.destroy_all

    redirect_to shopping_list_items_path, notice: "Inköpslistan tömdes."
  end

  private

  def set_item
    @item = Current.user.shopping_list_items.find(params[:id])
  end
end
