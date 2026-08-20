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

  # nil for a public collection viewed anonymously/by an unrelated user — there's
  # no relationship to label in that case, as opposed to owner/editor/viewer which
  # always describes a real relationship between the given user and the collection.
  def collection_role_label(collection, user = Current.user)
    return nil unless user
    return "Ägare" if collection.owned_by?(user)

    collaborator = collection.collection_collaborators.find_by(user: user)
    return nil unless collaborator

    collaborator.editor? ? "Redigera" : "Visa"
  end
end
