module IngredientDisplay
  extend ActiveSupport::Concern

  def display_name
    name.presence || content
  end

  def formatted_amount
    [ quantity, unit ].compact_blank.join(" ").presence
  end
end
