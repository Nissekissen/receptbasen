class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :collections
  has_many :saved_recipes
  has_many :recipes, through: :saved_recipes
  has_many :memberships
  has_many :groups, through: :memberships
  has_many :owned_groups, class_name: "Group", foreign_key: :owner_id, inverse_of: :owner
  has_many :shopping_list_items
  has_many :personal_recipe_notes
  has_many :cook_logs

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
end
