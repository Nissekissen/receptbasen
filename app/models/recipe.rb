class Recipe < ApplicationRecord
  TRACKING_PARAMS = %w[
    utm_source utm_medium utm_campaign utm_term utm_content utm_id
    fbclid gclid msclkid mc_cid mc_eid ref igshid si
  ].freeze

  normalizes :source_url, with: ->(url) do
    return url if url.nil?

    uri = URI.parse(url)
    return url if uri.host.nil?

    uri.host = uri.host.downcase.sub(/\Awww\./, "")
    uri.path = uri.path.sub(%r{/+\z}, "")
    uri.fragment = nil

    if uri.query.present?
      params = URI.decode_www_form(uri.query).reject { |key, _| TRACKING_PARAMS.include?(key) }
      uri.query = params.empty? ? nil : URI.encode_www_form(params)
    end

    uri.to_s
  rescue URI::InvalidURIError
    url
  end

  normalizes :source_domain, with: ->(domain) do
    PublicSuffix.domain(domain.to_s.downcase) || domain
  rescue PublicSuffix::Error
    domain
  end

  enum :status, { pending: 0, done: 1, failed: 2 }

  validates :source_url, presence: { unless: :manual? }, uniqueness: { allow_nil: true }
  validates :owner_id, absence: true, if: :source_url?

  has_many :ingredients
  has_many :steps, -> { order(:position) }
  has_many :taggings
  has_many :tags, through: :taggings
  has_many :saved_recipes
  has_many :collections, through: :saved_recipes

  def published?
    published_at.present?
  end

  def publish!
    update!(published_at: Time.current)
  end

  def manual?
    owner_id.present?
  end
end
