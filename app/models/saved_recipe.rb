class SavedRecipe < ApplicationRecord
  belongs_to :user
  belongs_to :collection
  belongs_to :recipe

  validates :recipe_id, uniqueness: { scope: :collection_id }
end
