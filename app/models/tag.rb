class Tag < ApplicationRecord
  has_many :taggings
  has_many :recipes, through: :taggings

  validates :name, presence: true, uniqueness: true
end
