module GroupsHelper
  def member_initials(user)
    user.name.split.map { |part| part[0] }.join.upcase.first(2)
  end

  def group_recipe_count(group)
    Recipe.where(id: SavedRecipe.where(collection_id: group.collections.select(:id)).select(:recipe_id)).count
  end
end
