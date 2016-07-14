class CreateItems < ActiveRecord::Migration[5.0]
  def change
    create_table :items do |t|
      t.string :index_name, :null => false, :default => ""
      t.string :doc_type, :null => false, :default => ""
      t.string :doc_uid, :null => false, :default => ""
      t.string :doc_parent, :null => false, :default => ""
      t.string :doc_mappings, :null => false, :default => ""
      t.text :doc_data, :null => false, :default => ""
      t.datetime :indexed_at

      t.timestamps
    end

    add_index :items, :doc_uid, :unique => true
  end
end
