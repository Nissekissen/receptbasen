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

  # Ratings needed before a recipe's own average outweighs the catalog-wide average.
  POPULARITY_TRUST_THRESHOLD = 5
  POPULARITY_WINDOW = 30.days
  POPULARITY_COOK_WEIGHT = 3
  POPULARITY_SAVE_WEIGHT = 1
  POPULARITY_RATING_WEIGHT = 2

  scope :catalog, -> { where(status: :done, owner_id: nil).where.not(published_at: nil) }

  # Score = (recent cooks × POPULARITY_COOK_WEIGHT) + (recent saves × POPULARITY_SAVE_WEIGHT)
  #       + (Bayesian-shrunk average rating × POPULARITY_RATING_WEIGHT)
  scope :order_by_popularity, ->(limit = 12) {
    global_avg = PersonalRecipeNote.where.not(rating: nil).average(:rating) || 3.0

    popularity_score = sanitize_sql_array([ <<~SQL.squish, cutoff: POPULARITY_WINDOW.ago, avg: global_avg, trust: POPULARITY_TRUST_THRESHOLD, cook_weight: POPULARITY_COOK_WEIGHT, save_weight: POPULARITY_SAVE_WEIGHT, rating_weight: POPULARITY_RATING_WEIGHT ])
      recipes.*, (
        (SELECT COUNT(*) FROM cook_logs WHERE cook_logs.recipe_id = recipes.id AND cook_logs.created_at > :cutoff) * :cook_weight
        + (SELECT COUNT(*) FROM saved_recipes WHERE saved_recipes.recipe_id = recipes.id AND saved_recipes.created_at > :cutoff) * :save_weight
        + (
            (COALESCE((SELECT COUNT(*) FROM personal_recipe_notes WHERE personal_recipe_notes.recipe_id = recipes.id AND rating IS NOT NULL), 0)
              * COALESCE((SELECT AVG(rating) FROM personal_recipe_notes WHERE personal_recipe_notes.recipe_id = recipes.id), :avg)
            + :trust * :avg)
            / (COALESCE((SELECT COUNT(*) FROM personal_recipe_notes WHERE personal_recipe_notes.recipe_id = recipes.id AND rating IS NOT NULL), 0) + :trust)
          ) * :rating_weight
      ) AS popularity_score
    SQL

    select(popularity_score).order("popularity_score DESC").limit(limit)
  }
  scope :order_by_cook_count, ->(limit = 12) {
    select("recipes.*, (SELECT COUNT(*) FROM cook_logs WHERE cook_logs.recipe_id = recipes.id) AS cook_count")
      .order("cook_count DESC")
      .limit(limit)
  }

  scope :order_by_published_at, ->(limit = 12) {
    order("published_at DESC")
      .limit(limit)
  }

  def published?
    published_at.present?
  end

  def publish!
    update!(published_at: Time.current)
  end

  def manual?
    owner_id.present?
  end

  def total_minutes
    return (ActiveSupport::Duration.parse(total_time) / 60).round if total_time.present?

    parts = [ prep_time, cook_time ].select(&:present?).filter_map do |value|
      ActiveSupport::Duration.parse(value)
    rescue ActiveSupport::Duration::ISO8601Parser::ParsingError
      nil
    end
    return nil if parts.empty?

    (parts.sum(0.seconds) / 60).round
  end

  def time_tag
    minutes = total_minutes
    return nil unless minutes

    name = if minutes <= 30
      "snabbt"
    elsif minutes >= 120
      "långkok"
    end
    return nil unless name

    Tag.find_or_create_by!(name: name) { |t| t.category = :tid }
  end

  def apply_extracted_tags!(tags)
    return if tags.blank?

    extracted = tags.map { |tag| Tag.find_or_create_by!(name: tag[:name]) { |t| t.category = tag[:category] } }
    extracted << time_tag if time_tag

    self.tags = extracted
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
