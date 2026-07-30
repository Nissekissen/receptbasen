class Group < ApplicationRecord
  belongs_to :owner, class_name: "User"

  has_many :memberships
  has_many :members, through: :memberships, source: :user

  validates :name, presence: true

  def member?(user)
    memberships.exists?(user: user)
  end

  # Owner or admin — anyone who can rename the group, manage invites, or
  # remove regular members. Deleting the group is owner-only, checked separately.
  def manager?(user)
    user == owner || memberships.exists?(user: user, admin: true)
  end
end
