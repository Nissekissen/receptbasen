class CollectionCollaboratorsController < ApplicationController
  layout false, only: :search
  before_action :set_collection
  before_action :require_owner
  before_action :set_collaborator, only: %i[update destroy]

  def search
    if params[:q].to_s.strip.length < 2
      @users = User.none
      return
    end

    downcased = params[:q].to_s.strip.downcase

    @users = User
      .where("LOWER(username) LIKE :q or LOWER(name) like :q", q: "%#{User.sanitize_sql_like(downcased)}%")
      .where.not(id: @collection.user_id)
      .where.not(id: @collection.collaborators.select(:id))
      .order(:name)
      .limit(8)
  end

  def create
    @collaborator = @collection.collection_collaborators.new(user_id: params[:user_id], role: :viewer)

    respond_to do |format|
      if @collaborator.save
        format.turbo_stream
        format.html { redirect_to collection_path(@collection) }
      else
        format.turbo_stream { head :unprocessable_content }
        format.html { redirect_to collection_path(@collection), alert: @collaborator.errors.full_messages.to_sentence }
      end
    end
  end

  def update
    @collaborator.update!(role: params[:role])

    head :no_content
  end

  def destroy
    @collaborator.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to collection_path(@collection) }
    end
  end

  private

  def set_collection
    @collection = Collection.find(params[:collection_id])
  end

  def require_owner
    raise ActiveRecord::RecordNotFound unless @collection.owned_by?(Current.user)
  end

  def set_collaborator
    @collaborator = @collection.collection_collaborators.find(params[:id])
  end
end
