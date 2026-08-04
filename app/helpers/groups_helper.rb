module GroupsHelper
  def member_initials(user)
    user.name.split.map { |part| part[0] }.join.upcase.first(2)
  end

  def group_recipe_count(group)
    Recipe.where(id: SavedRecipe.where(collection_id: group.collections.select(:id)).select(:recipe_id)).count
  end

  def group_delete_warning(group)
    "Tar bort gruppen permanent, tillsammans med #{pluralize(group.collections.count, 'samling', plural: 'samlingar')} och allt sparat innehåll i dem. Kan inte ångras."
  end

  def group_delete_confirm(group)
    "Ta bort \"#{group.name}\" och #{pluralize(group.collections.count, 'samling', plural: 'samlingar')} i den? Kan inte ångras."
  end

  def group_role_label(group, membership)
    return "Ägare" if membership.user == group.owner
    return "Admin" if membership.admin?

    nil
  end
end
