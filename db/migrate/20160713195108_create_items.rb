class CreateItems < ActiveRecord::Migration[5.0]
  def change
    create_table :items do |t|
      t.string :index
      t.string :type
      t.string :uid
      t.string :parent
      t.text :data
      t.datetime :indexed_at

      t.timestamps
    end

    add_index :items, [:type, :uid], :unique => true
  end
end
