class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :collections
  has_many :saved_recipes
  has_many :recipes, through: :saved_recipes

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
end
