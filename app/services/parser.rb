class Parser
  FIELDS = %i[title description image_url prep_time cook_time total_time servings source_domain].freeze

  def call
    raise NotImplementedError
  end

  private

  def normalize(result)
    result.symbolize_keys.slice(*FIELDS)
  end
end
