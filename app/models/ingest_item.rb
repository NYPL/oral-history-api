class IngestItem < ApplicationRecord

  def self.getLastDate(source)
    date = Item.getVeryEarlyDate
    item = IngestItem.order(:created_at).last
    date = item[:created_at] if item
    date
  end

  def self.isUpToDate(uid, source, date)
    IngestItem.where("doc_uid = ? AND source = ? AND created_at > ?", uid, source, date).first
  end

  def self.save(entry)
    IngestItem.create(entry)
  end

end
