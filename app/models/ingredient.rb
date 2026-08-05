class Ingredient < ApplicationRecord
  include IngredientDisplay

  belongs_to :recipe
end
