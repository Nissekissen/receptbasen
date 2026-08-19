class CollectionCollaborator < ApplicationRecord
  belongs_to :user
  belongs_to :collection

  enum :role, { viewer: 0, editor: 1 }
end
