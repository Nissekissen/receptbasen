class Recipe < ApplicationRecord
  enum :status, { pending: 0, done: 1, failed: 2 }

  validates :source_url, presence: true

  def published?
    published_at.present?
  end

  def publish!
    update!(published_at: Time.current)
  end
end
