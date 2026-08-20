class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :collections
  has_many :saved_recipes
  has_many :recipes, through: :saved_recipes
  has_many :shopping_list_items
  has_many :personal_recipe_notes
  has_many :cook_logs
  has_many :collection_collaborators

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :username, with: ->(u) { u.strip.downcase }

  before_validation :generate_username, if: -> { username.blank? }

  validates :name, presence: true
  validates :username, presence: true, uniqueness: true, format: { with: /\A[a-z0-9_]+\z/ }

  def editable_shared_collections
    Collection.where(id: collection_collaborators.editor.select(:collection_id))
  end

  private

  def generate_username
    base = name.to_s.parameterize(separator: "").first(20)
    base = "user" if base.blank?

    candidate = base
    suffix = 1
    while User.exists?(username: candidate)
      suffix += 1
      candidate = "#{base}#{suffix}"
    end

    self.username = candidate
  end
end
