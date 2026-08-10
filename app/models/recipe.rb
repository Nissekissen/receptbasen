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
  has_many :cook_logs
  has_many :personal_recipe_notes
  belongs_to :owner, class_name: "User", optional: true

  scope :catalog, -> { where(status: :done, owner_id: nil).where.not(published_at: nil) }

  def published?
    published_at.present?
  end

  def publish!
    update!(published_at: Time.current)
  end

  def manual?
    owner_id.present?
  end

  def visible_to?(user)
    return true unless manual?
    return false unless user
    return true if user == owner

    Membership.exists?(user: user, group_id: collections.where.not(group_id: nil).select(:group_id))
  end

  # Loops through all the words, find all recipes where the query
  # is found either in the title or in an ingredient and returns
  # only the recipes where all words match something.
  def self.search(query)
    return all if query.blank?

    query.to_s.split(" ").map { |w| "%#{sanitize_sql_like(w)}%" }.reduce(all) do |scope, pattern|
      title_matches = where("LOWER(title) LIKE LOWER(?)", pattern) # Lower only handles ASCII characters in SQLite, fixed in production.
      ingredient_matches = Ingredient.where("LOWER(name) LIKE LOWER(?) OR LOWER(content) LIKE LOWER(?)", pattern, pattern).select(:recipe_id)
      tagging_matches = Tagging.joins(:tag).where("LOWER(tags.name) LIKE LOWER(?)", pattern).select(:recipe_id)

      scope.where(id: title_matches.or(where(id: ingredient_matches)).select(:id).or(where(id: tagging_matches)))
    end
  end
end
