class Tag < ApplicationRecord
  enum :category, { maltidstyp: 0, kok: 1, kost: 2, svarighetsgrad: 3, tid: 4 }

  has_many :taggings
  has_many :recipes, through: :taggings

  validates :name, presence: true, uniqueness: true
  validates :category, presence: true
end
