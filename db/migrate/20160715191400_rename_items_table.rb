class RenameItemsTable < ActiveRecord::Migration[5.0]
  def change
    rename_table :items, :documents
  end
end
