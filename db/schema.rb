# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_19_211406) do
  create_table "collection_collaborators", force: :cascade do |t|
    t.integer "collection_id", null: false
    t.datetime "created_at", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["collection_id"], name: "index_collection_collaborators_on_collection_id"
    t.index ["user_id", "collection_id"], name: "index_collection_collaborators_on_user_id_and_collection_id", unique: true
    t.index ["user_id"], name: "index_collection_collaborators_on_user_id"
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "locked", default: false, null: false
    t.string "name", null: false
    t.boolean "public", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "cook_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["recipe_id"], name: "index_cook_logs_on_recipe_id"
    t.index ["user_id", "created_at"], name: "index_cook_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_cook_logs_on_user_id"
  end

  create_table "ingredients", force: :cascade do |t|
    t.string "content"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "quantity"
    t.float "quantity_value"
    t.integer "recipe_id", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["recipe_id"], name: "index_ingredients_on_recipe_id"
  end

  create_table "personal_recipe_notes", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "rating"
    t.integer "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["recipe_id"], name: "index_personal_recipe_notes_on_recipe_id"
    t.index ["user_id", "recipe_id"], name: "index_personal_recipe_notes_on_user_id_and_recipe_id", unique: true
    t.index ["user_id"], name: "index_personal_recipe_notes_on_user_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "cook_time"
    t.datetime "created_at", null: false
    t.string "description"
    t.float "external_rating"
    t.integer "external_rating_count"
    t.string "image_url"
    t.integer "owner_id"
    t.string "prep_time"
    t.datetime "published_at"
    t.string "servings"
    t.string "source_domain"
    t.string "source_url"
    t.integer "status", default: 0, null: false
    t.string "title"
    t.string "total_time"
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_recipes_on_owner_id"
    t.index ["source_url"], name: "index_recipes_on_source_url", unique: true
  end

  create_table "saved_recipes", force: :cascade do |t|
    t.integer "collection_id", null: false
    t.datetime "created_at", null: false
    t.text "note"
    t.integer "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["collection_id", "recipe_id"], name: "index_saved_recipes_on_collection_id_and_recipe_id", unique: true
    t.index ["collection_id"], name: "index_saved_recipes_on_collection_id"
    t.index ["recipe_id"], name: "index_saved_recipes_on_recipe_id"
    t.index ["user_id"], name: "index_saved_recipes_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "shopping_list_items", force: :cascade do |t|
    t.boolean "checked", default: false, null: false
    t.string "content", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.string "quantity"
    t.integer "recipe_id"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["recipe_id"], name: "index_shopping_list_items_on_recipe_id"
    t.index ["user_id"], name: "index_shopping_list_items_on_user_id"
  end

  create_table "steps", force: :cascade do |t|
    t.string "content", null: false
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.integer "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "position"], name: "index_steps_on_recipe_id_and_position", unique: true
    t.index ["recipe_id"], name: "index_steps_on_recipe_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "recipe_id", null: false
    t.integer "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "tag_id"], name: "index_taggings_on_recipe_id_and_tag_id", unique: true
    t.index ["recipe_id"], name: "index_taggings_on_recipe_id"
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
  end

  create_table "tags", force: :cascade do |t|
    t.integer "category", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "collection_collaborators", "collections", on_delete: :cascade
  add_foreign_key "collection_collaborators", "users", on_delete: :cascade
  add_foreign_key "collections", "users", on_delete: :cascade
  add_foreign_key "cook_logs", "recipes", on_delete: :cascade
  add_foreign_key "cook_logs", "users", on_delete: :cascade
  add_foreign_key "ingredients", "recipes", on_delete: :cascade
  add_foreign_key "personal_recipe_notes", "recipes", on_delete: :cascade
  add_foreign_key "personal_recipe_notes", "users", on_delete: :cascade
  add_foreign_key "recipes", "users", column: "owner_id", on_delete: :cascade
  add_foreign_key "saved_recipes", "collections", on_delete: :cascade
  add_foreign_key "saved_recipes", "recipes", on_delete: :cascade
  add_foreign_key "saved_recipes", "users", on_delete: :cascade
  add_foreign_key "sessions", "users"
  add_foreign_key "shopping_list_items", "recipes"
  add_foreign_key "shopping_list_items", "users"
  add_foreign_key "steps", "recipes", on_delete: :cascade
  add_foreign_key "taggings", "recipes", on_delete: :cascade
  add_foreign_key "taggings", "tags", on_delete: :cascade
end
