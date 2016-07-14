require 'elasticsearch'

namespace :index do

  # Usage rake index:build[100]
  # Usage rake index:build[100,rebuild]
  desc "Build elastic search index"
  task :build, [:batch_size, :rebuild] => :environment do |task, args|
    args.with_defaults(:batch_size => 500, :rebuild => false)

    # Connect to elastic client
    client = Elasticsearch::Client.new host: elastic_connection_string

    # Get items in elastic format for indexing
    items = get_elastic_items(args.rebuild)

    # Create batches of items to index in bulk
    batches = batch_list(items, args.batch_size)

    # CREATE/PUT in batches
    batch_count = batches.length
    batches.each_with_index do |batch, i|
      puts "Indexing batch #{i+1} of #{batch_count}"
      client.bulk body: batch

      # Mark items as indexed
      ids = batch.map { |item| item[:index][:_id] }
      Item.markListAsIndexed(ids)
    end

  end

  def batch_list(list, size)
    batches = []
    batch_count = (Float(list.length) / size).ceil

    batch_count.times do |i|
      if i >= batch_count-1
        batches << list[i*size..-1]
      else
        batches << list[i*size, size]
      end
    end

    batches
  end

  def elastic_connection_string
    "#{ENV['PROTOCOL']}#{ENV['ELASTIC_USER']}:#{ENV['ELASTIC_PASSWORD']}@#{ENV['ELASTIC_HOST']}"
  end

  def get_elastic_items(rebuild)
    items = Item.getItemsForIndexing
    items = Item.all if rebuild
    elastic = []

    items.each do |item|
      entry = {
        _index: item[:index_name],
        _type: item[:doc_type],
        _id: item[:doc_uid]
      }
      # parse data
      entry[:data] = JSON.parse(item[:doc_data])
      # add parent if present
      if item[:doc_parent].present?
        entry[:_parent] = item[:doc_parent]
      end
      # add mappings if present
      if item[:doc_mappings].present?
        entry[:data]["mappings"] = JSON.parse(item[:doc_mappings])
      end
      # add as index action
      elastic << {index: entry}
    end

    elastic
  end

end
