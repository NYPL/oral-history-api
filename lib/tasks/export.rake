require 'csv'
require 'json'

namespace :export do

  # Usage rake export:csv
  desc "Export data to CSV"
  task :csv, [:dir, :texts_filename, :docs_filename] => :environment do |task, args|
    args.with_defaults(:dir => 'data', :texts_filename => 'document_texts.csv', :docs_filename => 'documents.csv')

    # get file paths
    textsFile = Rails.root.join(args.dir, args.texts_filename)
    documentsFile = Rails.root.join(args.dir, args.docs_filename)

    # retrieve data
    docs = Document.getDocumentsForExporting
    docs_index = docs.map(&:doc_uid)
    rows = Document.getTextDocumentsForExporting
    puts "Writing #{rows.length} rows to file #{textsFile}"

    CSV.open(textsFile, "w") do |csv|
      headers = ["document", "text", "start", "end"]
      csv << headers

      rows.each_with_index do |row, i|
        # check for parent index
        parent_index = docs_index.index row[:doc_parent]
        if parent_index.nil?
          puts "Couldn't find parent #{parent}"
          next
        end

        # get columns
        text = ""
        data = JSON.parse(row[:doc_data])
        ms_start = data['start']
        ms_end = data['end']
        text = data['text'] if row[:doc_type] == 'annotation'
        text = data['best_text'] if row[:doc_type] == 'line'

        # add row
        csv << [parent_index, text, ms_start, ms_end] unless text.blank?
      end
    end

    puts "Writing #{docs.length} documents to file #{documentsFile}"
    CSV.open(documentsFile, "w") do |csv|
      headers = ["index", "id", "url", "title", "audio_url", "image_url"]
      csv << headers

      docs.each_with_index do |doc, i|
        data = JSON.parse(doc[:doc_data])
        id = doc[:doc_uid]
        url = "http://oralhistory.nypl.org/interviews/#{id}"
        image_url = ""
        image_url = data['image_url'] unless data['image_url'].blank?
        csv << [i, id, url, data['title'], data['audio_url'], image_url]
      end
    end
  end

end
