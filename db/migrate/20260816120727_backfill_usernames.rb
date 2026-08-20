class BackfillUsernames < ActiveRecord::Migration[8.1]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    used = MigrationUser.where.not(username: nil).pluck(:username).to_set

    MigrationUser.where(username: nil).find_each do |user|
      base = user.name.to_s.parameterize(separator: "").first(20)
      base = "user" if base.blank?

      candidate = base
      suffix = 1
      while used.include?(candidate)
        suffix += 1
        candidate = "#{base}#{suffix}"
      end

      used << candidate
      user.update_column(:username, candidate)
    end
  end

  def down
  end
end
