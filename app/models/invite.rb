class Invite < ApplicationRecord
  belongs_to :group
  belongs_to :created_by, class_name: "User"
  validates :token, presence: true
  before_validation :generate_token

  def active?
    revoked_at.nil?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64
  end
end
