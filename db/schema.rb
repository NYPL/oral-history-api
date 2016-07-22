# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160722162444) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "documents", force: :cascade do |t|
    t.string   "doc_type",   default: "", null: false
    t.string   "doc_uid",    default: "", null: false
    t.string   "doc_parent", default: "", null: false
    t.text     "doc_data",   default: "", null: false
    t.datetime "indexed_at"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["doc_uid"], name: "index_documents_on_doc_uid", unique: true, using: :btree
  end

  create_table "ingest_items", force: :cascade do |t|
    t.string   "doc_uid",    default: "", null: false
    t.string   "source",     default: "", null: false
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["doc_uid", "source"], name: "index_ingest_items_on_doc_uid_and_source", using: :btree
  end

end
