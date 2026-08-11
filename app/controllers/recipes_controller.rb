class RecipesController < ApplicationController
  allow_unauthenticated_access only: %i[new show create destroy]

  def new
  end

  def show
    @recipe = Recipe.find(params[:id])
    raise ActiveRecord::RecordNotFound if @recipe.manual? && !@recipe.visible_to?(authenticated? ? Current.user : nil)
    return request_authentication if @recipe.done? && !@recipe.published? && !authenticated?

    @collections = Current.user.collections.where(group_id: nil) if authenticated?
  end

  def create
    existing = Recipe.find_by(source_url: params[:url])
    return redirect_to existing if existing

    recipe = Recipe.create!(source_url: params[:url], status: :pending)
    ParseRecipeJob.set(wait: 1.second).perform_later(recipe.id)
    redirect_to recipe
  end

  def index
    @recipes = Recipe.where(id: Current.user.saved_recipes.select(:recipe_id))
    @recipes = @recipes.where(id: SavedRecipe.where(collection_id: params[:collection_id]).select(:recipe_id)) if params[:collection_id].present?
    @recipes = @recipes.where(id: Tagging.where(tag_id: params[:maltidstyp_tag_id]).select(:recipe_id)) if params[:maltidstyp_tag_id].present?
    @recipes = @recipes.where(id: Tagging.where(tag_id: params[:kok_tag_id]).select(:recipe_id)) if params[:kok_tag_id].present?
    @recipes = @recipes.where(id: Tagging.where(tag_id: params[:kost_tag_id]).select(:recipe_id)) if params[:kost_tag_id].present?

    @collections = Current.user.collections.where(group_id: nil)
    @maltidstyp_tags = Tag.maltidstyp.order(:name)
    @kok_tags = Tag.kok.order(:name)
    @kost_tags = Tag.kost.order(:name)
  end

  def destroy
    recipe = Recipe.find(params[:id])

    if recipe.manual?
      raise ActiveRecord::RecordNotFound unless authenticated? && Current.user == recipe.owner
    else
      raise ActiveRecord::RecordNotFound if recipe.published?
    end

    recipe.destroy
    redirect_to root_path
  end

  def extract_tags
    @recipe = Recipe.find(params[:id])
    raise ActiveRecord::RecordNotFound if @recipe.manual? && Current.user != @recipe.owner

    tag_extractor = TagExtractor.new(title: @recipe.title, description: @recipe.description, ingredients: @recipe.ingredients.map(&:content))
    result = tag_extractor.call
    @recipe.apply_extracted_tags!(result)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @recipe }
    end
  end

  def add_to_shopping_list
    @recipe = Recipe.find(params[:id])
    raise ActiveRecord::RecordNotFound if @recipe.manual? && !@recipe.visible_to?(Current.user)

    @recipe.ingredients.each do |ingredient|
      Current.user.shopping_list_items.create!(
        content: ingredient.content,
        quantity: ingredient.quantity,
        unit: ingredient.unit,
        name: ingredient.name,
        recipe: @recipe
      )
    end

    respond_to { |f| f.turbo_stream; f.html { redirect_to @recipe, notice: "Ingredienserna lades till i inköpslistan." } }
  end

  def cook
    @recipe = Recipe.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @recipe.visible_to?(Current.user)
    render layout: "cook_mode"
  end

  def log_cook
    @recipe = Recipe.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @recipe.visible_to?(Current.user)
    @recipe.cook_logs.create!(user: Current.user)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to recipe_path(@recipe), notice: "Receptet har loggats" }
    end
  end
end
