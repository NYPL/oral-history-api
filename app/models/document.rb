class Document < ApplicationRecord

  before_create do
    # default to long time ago
    self.indexed_at = Document.getVeryEarlyDate
  end

  def self.getVeryEarlyDate
    "1970-01-01T00:00:00Z".to_datetime
  end

  def self.getDocumentsForExporting
    Document.where("doc_type = ?", "item")
  end

  # get everything that has been updated but not indexed
  def self.getDocumentsForIndexing
    Document.where("updated_at > indexed_at")
  end

  def self.getLastIndexedDate
    last_indexed_date = Document.getVeryEarlyDate
    last_indexed_document = Document.order(:indexed_at).last
    last_indexed_date = last_indexed_document[:indexed_at] if last_indexed_document
    last_indexed_date
  end

  def self.getTextDocumentsForExporting
    Document.where("doc_type = ? OR doc_type = ?", "annotation", "line").order("doc_type ASC, doc_parent ASC, id ASC")
  end

  def self.markListAsIndexed(list)
    Document.where(doc_uid: list).update_all(indexed_at: Time.now)
  end

  def self.saveEntry(entry, overwrite)
    document = Document.where(doc_uid: entry[:doc_uid]).first
    if document.present?
      # merge data and update
      existingData = JSON.parse(document[:doc_data])
      newData = JSON.parse(entry[:doc_data])
      if overwrite
        entry[:doc_data] = existingData.merge(newData)
      else
        entry[:doc_data] = newData.merge(existingData)
      end
      entry[:doc_data] = entry[:doc_data].to_json
      document.update(entry)

    else
      Document.create(entry)
    end
  end

  def markAsIndexed
    update_attributes(indexed_at: Time.now)
  end

end
