class PublicProfilesController < ApplicationController
  allow_unauthenticated_access

  def show
    @user = User.find_by!(username: params[:username])
    @public_collections = @user.collections
                                .where(public: true)
                                .left_joins(:saved_recipes)
                                .select("collections.*, COUNT(saved_recipes.id) AS recipes_count")
                                .group(:id)
  end
end
