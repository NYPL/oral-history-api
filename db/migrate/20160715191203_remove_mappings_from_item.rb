class RemoveMappingsFromItem < ActiveRecord::Migration[5.0]
  def change
    remove_column :items, :doc_mappings
  end
end
