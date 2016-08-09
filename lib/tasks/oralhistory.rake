require 'oralhistory'
require 'util'

namespace :oralhistory do

  include Util
  include Oralhistory

  # Usage rake oralhistory:ingest overwrite_metadata=false updated_after=2016-01-01 indexed_at=2016-01-01
  desc "Ingest items and annotations from oralhistory.nypl.org"
  task :ingest => :environment do

    # Default options
    options = {
      overwrite_metadata: true,
      updated_after: false,
      indexed_at: false
    }

    options[:overwrite_metadata] = (ENV['overwrite_metadata']=='true') unless ENV['overwrite_metadata'].nil?
    options[:updated_after] = ENV['updated_after'] unless ENV['updated_after'].nil?
    options[:indexed_at] = ENV['indexed_at'] unless ENV['indexed_at'].nil?

    # puts options.inspect
    # exit

    # Retrieve all the items after last indexed date
    source = "oralhistory.nypl.org"
    items = oh_get_items(source, options[:updated_after])
    total = items.length
    puts "Attempting to ingest #{total} items from #{source}"

    # Download and save each item
    items.each_with_index do |item, i|
      item_id = item["slug"]
      # check to see if data is up-to-date
      upToDate = IngestItem.isUpToDate(item_id, source, item["updated_at"].to_datetime)
      if upToDate
        puts "Skipping #{i+1} of #{total}"
        next
      end
      # otherwise, request data
      itemData = oh_get_item_data(item["url"])
      # puts itemData.inspect
      itemData.each do |entry|
        entry[:indexed_at] = options[:indexed_at].to_datetime if options[:indexed_at]
        Document.saveEntry(entry, options[:overwrite_metadata])
      end
      IngestItem.save({doc_uid: item_id, source: source})
      puts "Saved #{i+1} of #{total}"
    end
  end

end
