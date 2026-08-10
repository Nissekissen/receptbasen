class ExploreController < ApplicationController
  allow_unauthenticated_access

  def index
    @query = params[:q]
    @results = Recipe.catalog.search(@query) unless @query.blank?
    
    @kok_tags = Tag.kok.order(:name)
    @kok_tag = Tag.kok.find_by(id: params[:kok_tag_id])
    @results = Recipe.catalog.where(id: Tagging.where(tag: @kok_tag).select(:recipe_id)).order_by_popularity unless @kok_tag.nil?
  end
end
