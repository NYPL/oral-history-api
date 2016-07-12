require 'elasticsearch'

namespace :items do

  # Usage rake items:build['all', 100]
  desc "Build elastic search index"
  task :build, [:scope, :batch_size] => :environment do |task, args|
    args.with_defaults(:scope => "all", :batch_size => 100)

    client = Elasticsearch::Client.new host: elastic_connection_string
    batches = []

    if ["all", "items"].include?(args.scope)
      items = get_items
      item_batches = batch_list(items, batch_size)
      batches += item_batches
    end

    if ["all", "lines"].include?(args.scope)
      lines = get_lines
      line_batches = batch_list(lines, batch_size)
      batches += line_batches
    end

    if ["all", "annotations"].include?(args.scope)
      annotations = get_annotations
      annotation_batches = batch_list(annotations, batch_size)
      batches += annotation_batches
    end

    # CREATE/PUT in batches
    batch_count = batches.length
    batches.each_with_index do |batch, i|
      puts "Indexing batch #{i+1} of #{batch_count}"
      client.bulk body: batch
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

  def get_items
    [
      { index: { _index: "items", _type: "item", _id: item["id"], data: {
        "title": "",
        "description": "",
        "speakers": [],
        "collection": "",
        "collection_id": 1,
        "tags": [],
        "duration": 0,
        "mappings": {
          "line": {},
          "annotation": {}
        }
      } } }
    ]
  end

  def get_lines
    [
      { index: { _index: "lines", _type: "line", _id: line["id"], _parent: line["item_id"], data: {
        "text": "",
        "computer_text": "",
        "start": 0,
        "end": 0
      } } }
    ]
  end

  def get_annotations
    [
      { index: { _index: "annotations", _type: "annotation", _id: annotation["id"], _parent: annotation["item_id"], data: {
        "text": "",
        "start": 0,
        "end": 0
      } } }
    ]
  end

  def elastic_connection_string
    "#{ENV['PROTOCOL']}#{ENV['ELASTIC_USER']}:#{ENV['ELASTIC_PASSWORD']}@#{ENV['ELASTIC_HOST']}"
  end

end
