class IngestItem < ApplicationRecord

  def self.getLastDate(source)
    date = Document.getVeryEarlyDate
    document = IngestItem.where(source: source).order(:created_at).last
    date = document[:created_at] if document
    date
  end

  def self.isUpToDate(uid, source, date)
    IngestItem.where("doc_uid = ? AND source = ? AND created_at > ?", uid, source, date).first
  end

  def self.save(entry)
    IngestItem.create(entry)
  end

end
