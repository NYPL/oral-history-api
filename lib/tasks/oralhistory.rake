require 'util'
require 'oralhistory'

namespace :oralhistory do

  include Util
  include Oralhistory

  # Usage rake oralhistory:ingest
  # Usage rake oralhistory:ingest[overwrite]
  # Usage rake oralhistory:ingest[overwrite,2016-01-01]
  desc "Ingest items and annotations from oralhistory.nypl.org"
  task :ingest, [:overwrite, :updated_after] => :environment do |task, args|
    args.with_defaults(:overwrite => false, :updated_after => false)

    # Retrieve all the items after last indexed date
    source = "oralhistory.nypl.org"
    items = oh_get_items(source, args.updated_after)
    total = items.length
    puts "Attempting to ingest #{total} items from Oral History"

    # Download and save each item
    items.each_with_index do |item, i|
      # check to see if data is up-to-date
      upToDate = IngestItem.isUpToDate(item["slug"], source, item["updated_at"].to_datetime)
      if upToDate
        puts "Skipping #{i+1} of #{total}"
        next
      else
        IngestItem.save({doc_uid: item["slug"], source: source})
      end
      # otherwise, request data
      itemData = oh_get_item_data(item["url"])
      # puts itemData.inspect
      itemData.each do |entry|
        Item.saveEntry(entry, args.overwrite)
      end
      puts "Saved #{i+1} of #{total}"
    end

  end

end
