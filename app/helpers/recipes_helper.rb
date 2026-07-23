module RecipesHelper
  def loading_step_label(step)
    { fetch: "Hämtar recept", parse: "Analyserar recept", parse_ai: "Analyserar med AI", tags: "Lägger till taggar" }.fetch(step)
  end
end
