class ExploreController < ApplicationController
  allow_unauthenticated_access

  def index
    @query = params[:q]
    @results = Recipe.catalog.search(@query) unless @query.blank?
  end
end
