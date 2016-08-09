require 'optparse'
require 'transcripteditor'
require 'util'
require 'uri'

namespace :transcripteditor do

  include Util
  include Transcripteditor

  # Usage rake transcripteditor:ingest -- --overwrite-metadata=true --overwrite-lines=false --updated-after=2016-01-01 --indexed-at=2016-01-01
  desc "Ingest transcripts from Open Transcript Editor"
  task :ingest => :environment do |task, args|

    # Default options
    options = {
      overwrite_metadata: false,
      overwrite_lines: true,
      updated_after: false,
      indexed_at: false
    }

    # Parse options
    op = OptionParser.new
    op.banner = "Usage: rake transcripteditor:ingest [options]"
    op.on("-M", "--overwrite-metadata [true/false]", "Overwrite existing metadata") { |bool| options[:overwrite_metadata] = (bool=='true') }
    op.on("-l", "--overwrite-lines [true/false]", "Overwrite existing lines") { |bool| options[:overwrite_lines] = (bool=='true') }
    op.on("-u", "--updated-after [YYYY-MM-DD]", "Only include transcripts updated after date") { |date| options[:updated_after] = date }
    op.on("-i", "--indexed-at [YYYY-MM-DD]", "Mark transcript as indexed at specified date") { |date| options[:indexed_at] = date }
    args = op.order!(ARGV) {}
    op.parse!(args)

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
