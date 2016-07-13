require 'elasticsearch'

namespace :index do

  # Usage rake index:build[100]
  desc "Build elastic search index"
  task :build, [:batch_size] => :environment do |task, args|
    args.with_defaults(:batch_size => 100)

    client = Elasticsearch::Client.new host: elastic_connection_string

    items = get_elastic_items
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

  def get_elastic_items
    items = Item.getItemsForIndexing
    elastic = []

    items.each do |item|
      entry = {
        _index: item[:index],
        _type: item[:type],
        _id: item[:uid]
      }
      # parse data
      entry[:data] = JSON.parse(item[:data])
      # add parent if present
      if item[:parent].present?
        entry[:_parent] = item[:parent]
      end
      # add as index action
      elastic << {index: entry}
    end

    elastic
  end

end
