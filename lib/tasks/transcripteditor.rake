require 'transcripteditor'
require 'util'
require 'uri'

namespace :transcripteditor do

  include Util
  include Transcripteditor

  # Usage rake transcripteditor:ingest overwrite_metadata=true overwrite_lines=false updated_after=2016-01-01 indexed_at=2016-01-01
  desc "Ingest transcripts from Open Transcript Editor"
  task :ingest => :environment do |task, args|

    # Default options
    options = {
      overwrite_metadata: false,
      overwrite_lines: true,
      updated_after: false,
      indexed_at: false
    }

    options[:overwrite_metadata] = (ENV['overwrite_metadata']=='true') unless ENV['overwrite_metadata'].nil?
    options[:overwrite_lines] = (ENV['overwrite_lines']=='true') unless ENV['overwrite_lines'].nil?
    options[:updated_after] = ENV['updated_after'] unless ENV['updated_after'].nil?
    options[:indexed_at] = ENV['indexed_at'] unless ENV['indexed_at'].nil?

    # puts options.inspect
    # exit

    source = URI.parse(ENV['TRANSCRIPT_EDITOR_URL']).host
    items = te_get_items(source, options[:updated_after])
    total = items.length
    puts "Attempting to ingest #{total} items from #{source}"

    # Download and save each item
    items.each_with_index do |item, i|
      # check to see if data is up-to-date
      upToDate = IngestItem.isUpToDate(item["id"], source, item["updated_at"].to_datetime)
      if upToDate
        puts "Skipping #{i+1} of #{total}"
        next
      end

      item_json_url = item["files"]["json"]
      resp = te_get_item_json(item_json_url)

      if resp
        itemData = te_get_item_data(resp)
        itemData.each do |entry|
          entry[:indexed_at] = options[:indexed_at].to_datetime if options[:indexed_at]
          Document.saveEntry(entry, options[:overwrite_metadata])
        end

        lineData = te_get_line_data(resp)
        lineData.each do |entry|
          entry[:indexed_at] = options[:indexed_at].to_datetime if options[:indexed_at]
          Document.saveEntry(entry, options[:overwrite_lines])
        end

        IngestItem.save({doc_uid: item["id"], source: source})
        puts "Saved #{i+1} of #{total}"
      else
        puts "Failed #{i+1} of #{total}: could not read #{item_json_url}"
      end
    end
  end

end
