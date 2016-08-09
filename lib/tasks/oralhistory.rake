require 'optparse'
require 'oralhistory'
require 'util'

namespace :oralhistory do

  include Util
  include Oralhistory

  # Usage rake oralhistory:ingest -- --overwrite-metadata=true --updated-after=2016-01-01 --indexed-at=2016-01-01
  desc "Ingest items and annotations from oralhistory.nypl.org"
  task :ingest => :environment do |task, args|

    # Default options
    options = {
      overwrite_metadata: false,
      updated_after: false,
      indexed_at: false
    }

    # Parse options
    op = OptionParser.new
    op.banner = "Usage: rake oralhistory:ingest [options]"
    op.on("-M", "--overwrite-metadata [true/false]", "Overwrite existing metadata") { |bool| options[:overwrite_metadata] = (bool=='true') }
    op.on("-u", "--updated-after [YYYY-MM-DD]", "Only include transcripts updated after date") { |date| options[:updated_after] = date }
    op.on("-i", "--indexed-at [YYYY-MM-DD]", "Mark transcript as indexed at specified date") { |date| options[:indexed_at] = date }
    args = op.order!(ARGV) {}
    op.parse!(args)

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

    exit 0
  end

end
