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
    collections = Current.user.collections.where(group_id: nil).or(Collection.where(group_id: Current.user.groups.select(:id)))
    SavedRecipe.where(recipe: recipe, collection: collections).index_by(&:collection_id)
  end

  def current_user_note_for(recipe)
    return nil unless authenticated?
    PersonalRecipeNote.find_by(user: Current.user, recipe: recipe)
  end

  def current_user_cook_count_for(recipe)
    return 0 unless authenticated?
    recipe.cook_logs.where(user: Current.user).count
  end

  def recipe_total_time(recipe)
    return "#{(ActiveSupport::Duration.parse(recipe.total_time) / 60).round} min" if recipe.total_time.present?

    durations = [ recipe.prep_time, recipe.cook_time ].select(&:present?).filter_map do |duration|
      ActiveSupport::Duration.parse(duration)
    rescue ActiveSupport::Duration::ISO8601Parser::ParsingError
      nil
    end
    return nil if durations.empty?

    "#{(durations.sum(0.seconds) / 60).round} min"
  end

  def recipe_difficulty(recipe)
    recipe.tags.svarighetsgrad.first&.name&.capitalize
  end

  def recipe_difficulty_icon(difficulty)
    { "lätt" => "easy", "medel" => "medium", "avancerad" => "hard" }[difficulty&.downcase]
  end

  def recipe_rating(recipe)
    PersonalRecipeNote.where(recipe: recipe).where.not(rating: nil).pick(Arel.sql("AVG(rating), COUNT(rating)"))
  end

  # Matches "5 minuter"/"45 min"/"1 timme"/"2 timmar" — deliberately just the
  # first digit+unit pair found, so a range like "5-10 minuter" reads as 5.
  def step_duration_seconds(step)
    match = step.content.to_s.match(/(\d+)(?:-\d+)?\s*(timme|timmar|min(?:ut(?:er)?)?)\b/i)
    return nil unless match

    amount = match[1].to_i
    match[2].downcase.start_with?("tim") ? amount * 3600 : amount * 60
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
