class PersonalRecipeNote < ApplicationRecord
  belongs_to :user
  belongs_to :recipe

  validates :content, presence: true
  validates :user_id, uniqueness: { scope: :recipe_id }
end
