class RemoveIndexNameFromDocuments < ActiveRecord::Migration[5.0]
  def change
    remove_column :documents, :index_name
  end
end
