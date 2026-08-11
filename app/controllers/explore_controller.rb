class ExploreController < ApplicationController
  allow_unauthenticated_access

  def index
    @query = params[:q]
    @results = Recipe.catalog.search(@query) unless @query.blank?
    
    @kok_tags = Tag.kok.order(:name)
    @kok_tag = Tag.kok.find_by(id: params[:kok_tag_id])
    @results = Recipe.catalog.where(id: Tagging.where(tag: @kok_tag).select(:recipe_id)).order_by_popularity unless @kok_tag.nil?
    @shelves = [
      { title: "Populärt just nu", type: "big", recipes: Recipe.catalog.order_by_popularity(3) },
      { title: "Snabbt & enkelt", type: "row", recipes: Recipe.catalog.order_by_popularity(10) },
      { title: "Veckans favorit", type: "split", recipes: Recipe.catalog.order_by_popularity(5) },
      { title: "Nyss tillagda", type: "list", recipes: Recipe.catalog.order_by_popularity(8) },
      { title: "Helgmys eller vardagsmat?", type: "duo", groups: [{ label: "Helgmys", recipes: Recipe.catalog.order_by_popularity(4) }, { label: "Vardagsmat", recipes: Recipe.catalog.order_by_popularity(4) }] }
    ]
  end
end
