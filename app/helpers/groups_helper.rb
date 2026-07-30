module GroupsHelper
  def member_initials(user)
    user.name.split.map { |part| part[0] }.join.upcase.first(2)
  end
end
