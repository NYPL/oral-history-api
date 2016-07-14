class Item < ApplicationRecord

  before_create do
    # default to long time ago
    self.indexed_at = Item.getVeryEarlyDate
  end

  def self.defaultItemMappings
    obj = {"line": {}, "annotation": {}}
    obj.to_json
  end

  def self.getVeryEarlyDate
    "1970-01-01T00:00:00Z".to_datetime
  end

  # get everything that has been updated but not indexed
  def self.getItemsForIndexing
    Item.where("updated_at > indexed_at")
  end

  def self.getLastIndexedDate
    last_indexed_date = Item.getVeryEarlyDate
    last_indexed_item = Item.order(:indexed_at).last
    last_indexed_date = last_indexed_item[:indexed_at] if last_indexed_item
    last_indexed_date
  end

  def self.markListAsIndexed(list)
    Item.where(uid: list).update_all(indexed_at: Time.now)
  end

  def self.saveEntry(entry, overwrite)
    item = Item.where(doc_uid: entry[:doc_uid]).first
    if item.present?
      # merge data and update
      existingData = JSON.parse(item[:doc_data])
      newData = entry[:doc_data]
      if overwrite
        entry[:doc_data] = existingData.merge(newData)
      else
        entry[:doc_data] = newData.merge(existingData)
      end
      item.update(entry)

    else
      Item.create(entry)
    end
  end

  def markAsIndexed
    update_attributes(indexed_at: Time.now)
  end

end
