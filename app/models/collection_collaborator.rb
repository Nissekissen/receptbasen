class CollectionCollaborator < ApplicationRecord
  belongs_to :user
  belongs_to :collection

  enum :role, { viewer: 0, editor: 1 }

  validates :user_id, uniqueness: { scope: :collection_id }
  validate :owner_cannot_be_collaborator

  private

  def owner_cannot_be_collaborator
    return if collection.nil? || user.nil?

    errors.add(:user, "är redan ägare") if collection.owned_by?(user)
  end
end
