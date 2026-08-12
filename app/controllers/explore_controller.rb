class ExploreController < ApplicationController
  allow_unauthenticated_access

  SHELVES_PER_PAGE = 4

  def index
    @query = params[:q]
    @results = Recipe.catalog.search(@query) unless @query.blank?

    @kok_tags = Tag.kok.order(:name)
    @kok_tag = Tag.kok.find_by(id: params[:kok_tag_id])
    @results = Recipe.catalog.where(id: Tagging.where(tag: @kok_tag).select(:recipe_id)).order_by_popularity unless @kok_tag.nil?

    if @results.nil?
      if shelves_enabled?
        @shelves = shelves
      else
        @results = Recipe.catalog.order_by_popularity
      end
    end
  end

  private

  # Temporary escape hatch while the catalog is still small — shelves come back
  # half-empty without enough recipes. Remove this (and the fallback branch in
  # #index) once the catalog has grown enough that shelves reliably fill out.
  def shelves_enabled?
    ENV["DISABLE_EXPLORE_SHELVES"].blank?
  end

  def shelves
    rng = Random.new(Date.current.jd)
    shelf_pool.sample(SHELVES_PER_PAGE, random: rng).map(&:call).select { |shelf| shelf_has_content?(shelf) }
  end

  def shelf_pool
    [
      -> { { title: "Populärt just nu", type: "big", recipes: Recipe.catalog.order_by_popularity(3) } },
      -> { { title: "Snabbt & enkelt", type: "row", recipes: tag_shelf("snabbt").order_by_popularity(10) } },
      -> { { title: "Nyss tillagda", type: "list", recipes: Recipe.catalog.order(published_at: :desc).limit(8) } },
      -> { { title: "Middagsfavoriter", type: "row", recipes: tag_shelf("middag").order_by_popularity(10) } },
      -> { { title: "Sötsug", type: "row", recipes: tag_shelf([ "bakverk", "efterrätt" ]).order_by_popularity(10) } },
      -> { { title: "Frukost & fika", type: "row", recipes: tag_shelf([ "frukost", "mellanmål" ]).order_by_popularity(10) } },
      -> { { title: "Vegetariskt", type: "row", recipes: tag_shelf([ "vegetariskt", "veganskt" ]).order_by_popularity(10) } },
      -> { { title: "Mest lagade", type: "list", recipes: Recipe.catalog.order_by_cook_count(8) } }
    ]
  end

  def shelf_has_content?(shelf)
    shelf[:recipes].present? || shelf[:groups]&.any? { |g| g[:recipes].present? }
  end

  def tag_shelf(tag_names)
    tag_ids = Tag.where(name: Array(tag_names)).ids
    return Recipe.none if tag_ids.empty?

    Recipe.catalog.where(id: Tagging.where(tag_id: tag_ids).select(:recipe_id))
  end
end
