class Item < ApplicationRecord

  before_create do
    # default to long time ago
    self.indexed_at = "1970-01-01T00:00:00Z".to_datetime
  end

  # get everything that has been updated but not indexed
  def self.getItemsForIndexing
    Item.where("updated_at > indexed_at")
  end

  def self.getLastIndexedDate
    last_indexed_item = Item.order(:indexed_at).last
    last_indexed_item[:indexed_at]
  end

  def self.markListAsIndexed(list)
    Item.where(uid: list).update_all(indexed_at: Time.now)
  end

  def self.saveEntry(entry)
    item = Item.where("uid = :uid AND type = :type", entry)
    if item
      # merge data and update
      existingData = JSON.parse(item[:data])
      newData = entry[:data]
      entry[:data] = existingData.merge(newData)
      item.update(entry)

    else
      Item.create(entry)
    end
  end

  def markAsIndexed
    update_attributes(indexed_at: Time.now)
  end

end
