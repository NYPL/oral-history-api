require 'util'
require 'transcripteditor'
require 'uri'

namespace :transcripteditor do

  include Util
  include Transcripteditor

  # Usage rake transcripteditor:ingest_metadata
  # Usage rake transcripteditor:ingest_metadata[false]
  # Usage rake transcripteditor:ingest_metadata[overwrite_metadata,overwrite_lines]
  # Usage rake transcripteditor:ingest_metadata[overwrite_metadata,overwrite_lines,2016-01-01]
  desc "Ingest transcripts from Open Transcript Editor"
  task :ingest, [:url, :overwrite_metadata, :overwrite_lines, :updated_after] => :environment do |task, args|
    args.with_defaults(:overwrite_metadata => true, :overwrite_lines => true, :updated_after => false)

    source = URI.parse(ENV['TRANSCRIPT_EDITOR_URL']).host
    items = te_get_items(source, args.updated_after)
    total = items.length
    puts "Attempting to ingest #{total} items from Transcript Editor"

    return

    # Download and save each item
    items.each_with_index do |item, i|
      # check to see if data is up-to-date
      upToDate = IngestItem.isUpToDate(item["id"], source, item["updated_at"].to_datetime)
      if upToDate
        puts "Skipping #{i+1} of #{total}"
        next
      else
        IngestItem.save({doc_uid: item["id"], source: source})
      end

      resp = te_get_item_json(item["files"]["json"])

      if resp
        itemData = te_get_item_data(resp)
        itemData.each do |entry|
          Item.saveEntry(entry, args.overwrite_metadata)
        end

        lineData = te_get_line_data(resp)
        lineData.each do |entry|
          Item.saveEntry(entry, args.overwrite_lines)
        end

        puts "Saved #{i+1} of #{total}"
      else
        puts "Failed #{i+1} of #{total}"
      end
    end

  end

end
