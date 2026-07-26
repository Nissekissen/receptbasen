module CollectionsHelper
  def collection_count_label(collection)
    collection.recipes_count.zero? ? "Tomt" : "#{collection.recipes_count} recept"
  end

  # Returns nil for an empty collection so no confirmation dialog is attached —
  # there's nothing to lose, so a prompt would just be friction.
  def collection_delete_confirm(collection)
    count = collection.recipes_count
    return nil if count.zero?

    recipes = count == 1 ? "1 sparat recept" : "#{count} sparade recept"
    "Ta bort \"#{collection.name}\" och #{recipes} i den? Recepten finns kvar i Receptbasen, men du behöver spara dem igen."
  end
end
