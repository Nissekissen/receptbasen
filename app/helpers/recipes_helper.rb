module RecipesHelper
  def loading_step_label(step)
    { fetch: "Hämtar recept", parse: "Analyserar recept", parse_ai: "Analyserar med AI", tags: "Lägger till taggar" }.fetch(step)
  end

  def recipe_flow_step(recipe)
    return :ready if recipe.done?
    return :failed if recipe.failed?
    :working
  end

  def saved_recipe_lookup(recipe)
    Current.user.saved_recipes.where(recipe: recipe).index_by(&:collection_id)
  end

  def recipe_total_time(recipe)
    return "#{(ActiveSupport::Duration.parse(recipe.total_time) / 60).round} min" if recipe.total_time.present?

    durations = [recipe.prep_time, recipe.cook_time].compact.map { |duration| ActiveSupport::Duration.parse(duration) }
    return nil if durations.empty?

    "#{(durations.sum(0.seconds) / 60).round} min"
  end

  def recipe_difficulty(recipe)
    recipe.tags.svarighetsgrad.first&.name&.capitalize
  end

  def recipe_difficulty_icon(difficulty)
    { "lätt" => "easy", "medel" => "medium", "avancerad" => "hard" }[difficulty&.downcase]
  end

  def active_recipe_filters(collections: Current.user.collections)
    filters = []
    filters << { param: :collection_id, label: collections.find_by(id: params[:collection_id])&.name } if params[:collection_id].present?
    filters << { param: :maltidstyp_tag_id, label: Tag.find_by(id: params[:maltidstyp_tag_id])&.name&.capitalize } if params[:maltidstyp_tag_id].present?
    filters << { param: :kok_tag_id, label: Tag.find_by(id: params[:kok_tag_id])&.name&.capitalize } if params[:kok_tag_id].present?
    filters << { param: :kost_tag_id, label: Tag.find_by(id: params[:kost_tag_id])&.name&.capitalize } if params[:kost_tag_id].present?
    filters.select { |filter| filter[:label].present? }
  end
end
