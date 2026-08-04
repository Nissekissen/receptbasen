class GroupCollectionsController < ApplicationController
  before_action :set_group
  before_action :set_collection, only: %i[update destroy]
  before_action :require_manager, only: %i[create update destroy]

  def index
    raise ActiveRecord::RecordNotFound unless @group.member?(Current.user)

    @collections = @group.collections
                         .left_joins(:saved_recipes)
                         .select("collections.*, COUNT(saved_recipes.id) AS recipes_count")
                         .group(:id)
                         .order(locked: :desc, name: :asc)
  end

  def create
    collection = @group.collections.new(collection_params)
    collection.user = Current.user

    if collection.save
      redirect_to group_collections_path(@group), notice: "Samlingen skapades."
    else
      redirect_to group_collections_path(@group), alert: collection.errors.full_messages.to_sentence
    end
  end

  # Same locked-collection shape as CollectionsController#update: a locked
  # collection aborts the update in a before_update callback, so this returns
  # false without raising rather than needing a separate branch.
  def update
    if @collection.update(collection_params)
      redirect_to group_collections_path(@group), notice: "Namnet ändrades."
    else
      redirect_to group_collections_path(@group), alert: "Det gick inte att byta namn på samlingen."
    end
  end

  def destroy
    if @collection.destroy
      redirect_to group_collections_path(@group), notice: "Samlingen togs bort."
    else
      redirect_to group_collections_path(@group), alert: "Den samlingen kan inte tas bort."
    end
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  # Scoped through @group so one group's manager can't touch another group's collection.
  def set_collection
    @collection = @group.collections.find(params[:id])
  end

  def require_manager
    raise ActiveRecord::RecordNotFound unless @group.manager?(Current.user)
  end

  def collection_params
    params.expect(collection: [ :name ])
  end
end
