class CollectionsController < ApplicationController
  before_action :set_collection, only: %i[update destroy]

  def index
    @collections = Current.user.collections
                                .left_joins(:saved_recipes)
                                .select("collections.*, COUNT(saved_recipes.id) AS recipes_count")
                                .group(:id)
                                .order(locked: :desc, name: :asc)
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
      redirect_to collections_path, notice: "Namnet ändrades."
    else
      redirect_to collections_path, alert: "Det gick inte att byta namn på samlingen."
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

  private

  # Scoped through Current.user so one user can't touch another user's collections.
  def set_collection
    @collection = Current.user.collections.find(params[:id])
  end

  def collection_params
    params.expect(collection: [ :name ])
  end
end
