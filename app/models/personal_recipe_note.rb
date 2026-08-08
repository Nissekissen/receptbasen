class PersonalRecipeNote < ApplicationRecord
  belongs_to :user
  belongs_to :recipe

  validates :content, presence: true, unless: -> { rating.present? }
  validates :rating, allow_nil: true, numericality: { in: 1..5 }
  validates :user_id, uniqueness: { scope: :recipe_id }
end
