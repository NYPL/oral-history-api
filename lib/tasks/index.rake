require 'elasticsearch'

namespace :index do

  # Usage rake index:build[100]
  # Usage rake index:build[100,rebuild]
  desc "Build elastic search index"
  task :build, [:batch_size, :rebuild] => :environment do |task, args|
    args.with_defaults(:batch_size => 500, :rebuild => false)

    # Connect to elastic client
    client = Elasticsearch::Client.new host: elastic_connection_string

    # Get documents in elastic format for indexing
    documents = get_elastic_documents(args.rebuild)

    # Create batches of documents to index in bulk
    batches = batch_list(documents, args.batch_size)

    # CREATE/PUT in batches
    batch_count = batches.length
    batches.each_with_index do |batch, i|
      puts "Indexing batch #{i+1} of #{batch_count}"
      client.bulk body: batch

      # Mark documents as indexed
      ids = batch.map { |document| document[:index][:_id] }
      Document.markListAsIndexed(ids)
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

  def get_elastic_documents(rebuild)
    documents = Document.getDocumentsForIndexing
    documents = Document.all if rebuild
    elastic = []

    documents.each do |document|
      entry = {
        _index: document[:index_name],
        _type: document[:doc_type],
        _id: document[:doc_uid]
      }
      # parse data
      entry[:data] = JSON.parse(document[:doc_data])
      # add parent if present
      if document[:doc_parent].present?
        entry[:_parent] = document[:doc_parent]
      end
      # add as index action
      elastic << {index: entry}
    end

    elastic
  end

  # Usage rake index:create
  desc "Create elastic search indices"
  task :create => :environment do |task, args|

  end

end
