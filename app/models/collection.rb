class Collection < ApplicationRecord
  belongs_to :user

  has_many :saved_recipes
  has_many :recipes, through: :saved_recipes

  validates :name, presence: true

  before_destroy :prevent_locked_deletion
  before_update :prevent_locked_rename

  private

  def prevent_locked_deletion
    throw :abort if locked?
  end

  def prevent_locked_rename
    throw :abort if locked? && will_save_change_to_name?
  end
end
