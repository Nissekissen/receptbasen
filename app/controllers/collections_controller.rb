class CollectionsController < ApplicationController
  before_action :set_collection, only: %i[update destroy]
  allow_unauthenticated_access only: %i[show]

  def index
    @owned = Current.user.collections
                                .left_joins(:saved_recipes)
                                .select("collections.*, COUNT(saved_recipes.id) AS recipes_count")
                                .group(:id)
                                .order(locked: :desc, name: :asc)
    @shared_with_me = Collection.joins(:collection_collaborators).where(collection_collaborators: { user: Current.user })
  end

  def show
    @collection = Collection.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @collection.accessible_to?(authenticated? ? Current.user : nil)

    @recipes = @collection.recipes
    @recipes = @recipes.where(id: Tagging.where(tag_id: params[:maltidstyp_tag_id]).select(:recipe_id)) if params[:maltidstyp_tag_id].present?
    @recipes = @recipes.where(id: Tagging.where(tag_id: params[:kok_tag_id]).select(:recipe_id)) if params[:kok_tag_id].present?
    @recipes = @recipes.where(id: Tagging.where(tag_id: params[:kost_tag_id]).select(:recipe_id)) if params[:kost_tag_id].present?

    @maltidstyp_tags = Tag.maltidstyp.order(:name)
    @kok_tags = Tag.kok.order(:name)
    @kost_tags = Tag.kost.order(:name)

    @can_manage = authenticated? && @collection.owned_by?(Current.user)
    @can_edit   = authenticated? && @collection.editable_by?(Current.user)

    @attributions = SavedRecipe.where(collection: @collection).includes(:user).index_by(&:recipe_id)
  end

  def create
    collection = Current.user.collections.new(collection_params)

    if collection.save
      redirect_to collections_path, notice: "Samlingen skapades."
    else
      redirect_to collections_path, alert: collection.errors.full_messages.to_sentence
    end
  end

  # A locked collection aborts the update in a before_update callback, which makes
  # `update` return false without raising — so the failure branch covers both a
  # blank name and an attempt to rename "Favoriter".
  def update
    if @collection.update(collection_params)
      redirect_back fallback_location: collections_path, notice: "Ändringarna sparades."
    else
      redirect_back fallback_location: collections_path, alert: "Det gick inte att spara ändringarna."
    end
  end

  # Same for destroy: the locked callback throws :abort, so this returns false
  # rather than raising. The UI doesn't render a delete button for locked
  # collections, but this covers a request that skips the UI.
  def destroy
    if @collection.destroy
      redirect_to collections_path, notice: "Samlingen togs bort."
    else
      redirect_to collections_path, alert: "Den samlingen kan inte tas bort."
    end
  end

  def leave
    @collection = Collection.find(params[:id])
    collaborator = @collection.collection_collaborators.find_by(user: Current.user)
    raise ActiveRecord::RecordNotFound if collaborator.nil?

    collaborator.destroy

    redirect_to collections_path, notice: "Du lämnade samlingen."
  end

  private

  # Scoped through Current.user so one user can't rename/destroy another user's
  # collection — Collection#user_id is unambiguous ownership now that collections
  # are never group-owned, so this scope alone is sufficient authorization.
  def set_collection
    @collection = Current.user.collections.find(params[:id])
  end

  def collection_params
    params.expect(collection: [ :name, :public ])
  end
end
