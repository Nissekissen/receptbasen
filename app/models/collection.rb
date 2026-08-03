class Collection < ApplicationRecord
  belongs_to :user
  belongs_to :group, optional: true

  has_many :saved_recipes
  has_many :recipes, through: :saved_recipes

  validates :name, presence: true

  before_destroy :prevent_locked_deletion
  before_update :prevent_locked_rename

  # CollectionsController#index supplies this as a COUNT in one query; the fallback
  # keeps the value correct for a Collection loaded any other way.
  def recipes_count
    attributes.fetch("recipes_count") { saved_recipes.count }
  end

  def accessible_to?(user)
    return false unless user
    return true if self.user == user

    group.present? && group.member?(user)
  end

  private

  def prevent_locked_deletion
    throw :abort if locked?
  end

  def prevent_locked_rename
    throw :abort if locked? && will_save_change_to_name?
  end
end
