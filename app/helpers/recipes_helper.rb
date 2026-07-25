module RecipesHelper
  def loading_step_label(step)
    { fetch: "Hämtar recept", parse: "Analyserar recept", parse_ai: "Analyserar med AI", tags: "Lägger till taggar" }.fetch(step)
  end

  def recipe_flow_step(recipe)
    return :ready if recipe.done?
    return :failed if recipe.failed?
    :working
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
end
