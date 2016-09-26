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
      headers = ["document", "type", "text", "start", "end"]
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
        type = row[:doc_type]
        ms_start = data['start']
        ms_end = data['end']
        text = data['text'] if type == 'annotation'
        text = data['best_text'] if type == 'line'

        # add row
        csv << [parent_index, type, text, ms_start, ms_end] unless text.blank?
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

  # Usage rake export:csv_combined
  desc "Export data to one combined CSV"
  task :csv_combined, [:dir, :filename] => :environment do |task, args|
    args.with_defaults(:dir => 'data', :filename => 'document_texts_verbose.csv')

    # get file paths
    textsFile = Rails.root.join(args.dir, args.filename)

    # retrieve data
    docs = Document.getDocumentsForExporting
    docs_index = docs.map(&:doc_uid)
    rows = Document.getTextDocumentsForExporting
    puts "Writing #{rows.length} rows to file #{textsFile}"

    CSV.open(textsFile, "w") do |csv|
      headers = ["parent_id", "type", "text", "start", "end", "url", "audio_url", "collection"]
      csv << headers

      rows.each_with_index do |row, i|
        # check for parent index
        parent_index = docs_index.index row[:doc_parent]
        if parent_index.nil?
          puts "Couldn't find parent #{parent}"
          next
        end
        parent = docs[parent_index]

        # get columns
        text = ""
        data = JSON.parse(row[:doc_data])
        type = row[:doc_type]
        ms_start = data['start']
        ms_end = data['end']
        text = data['text'] if type == 'annotation'
        text = data['best_text'] if type == 'line'

        # parent data
        parent_data = JSON.parse(parent[:doc_data])
        parent_id = parent[:doc_uid]
        seconds = (ms_start/1000).round
        hhmmss = Time.at(seconds).utc.strftime("%H:%M:%S")
        url = "http://oralhistory.nypl.org/interviews/#{parent_id}##{hhmmss}"
        audio_url = parent_data['audio_url']
        collection = ''
        unless parent_data['collection_id'].blank?
          collection = parent_data['collection_id'].gsub(/[^a-z ]/i, ' ')
        end

        # add row
        csv << [parent_id, type, text, ms_start, ms_end, url, audio_url, collection] unless text.blank?

        if i % 1000 == 0
          puts "#{(1.0*i/rows.length*100).round}% complete"
        end
      end
    end
  end

end
