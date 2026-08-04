class ShoppingListItem < ApplicationRecord
  belongs_to :user
  belongs_to :recipe, optional: true

  validates :content, presence: true
end
