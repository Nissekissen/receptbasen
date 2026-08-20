require "test_helper"

class CollectionCollaboratorTest < ActiveSupport::TestCase
  test "viewer? and editor? reflect the role" do
    assert collection_collaborators(:two_viewer_on_delad).viewer?
    assert_not collection_collaborators(:two_viewer_on_delad).editor?

    assert collection_collaborators(:three_editor_on_delad).editor?
    assert_not collection_collaborators(:three_editor_on_delad).viewer?
  end

  test "prevents a duplicate collaborator on the same collection" do
    duplicate = CollectionCollaborator.new(
      collection: collections(:delad_collection),
      user: users(:two),
      role: :editor
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "allows the same user to collaborate on different collections" do
    collaborator = CollectionCollaborator.new(
      collection: collections(:public_collection),
      user: users(:two),
      role: :viewer
    )

    assert collaborator.valid?
  end

  test "rejects the collection's own owner as a collaborator" do
    collaborator = CollectionCollaborator.new(
      collection: collections(:delad_collection),
      user: users(:one),
      role: :viewer
    )

    assert_not collaborator.valid?
    assert_includes collaborator.errors[:user], "är redan ägare"
  end
end
