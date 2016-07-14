class CreateIngestItems < ActiveRecord::Migration[5.0]
  def change
    create_table :ingest_items do |t|
      t.string :doc_uid, :null => false, :default => ""
      t.string :source, :null => false, :default => ""

      t.timestamps
    end

    add_index :ingest_items, [:doc_uid, :source]
  end
end
