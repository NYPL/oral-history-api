require 'elasticsearch'

namespace :index do

  # Usage rake index:build[500]
  # Usage rake index:build[500,rebuild]
  desc "Build elastic search index"
  task :build, [:batch_size, :rebuild] => :environment do |task, args|
    args.with_defaults(:batch_size => 500, :rebuild => false)

    batch_size = args.batch_size.to_i

    # Connect to elastic client
    client = Elasticsearch::Client.new host: elastic_connection_string

    # Get documents in elastic format for indexing
    puts "Retrieving documents for indexing..."
    documents = get_elastic_documents(args.rebuild)
    puts "#{documents.length} documents ready for indexing..."

    # Create batches of documents to index in bulk
    batches = batch_list(documents, batch_size)
    puts "#{batches.length} batches created of size #{batch_size}"

    # CREATE/PUT in batches
    batch_count = batches.length
    batches.each_with_index do |batch, i|
      puts "Indexing batch #{i+1} of #{batch_count}"
      client.bulk body: batch

      # Mark documents as indexed
      ids = batch.map { |document| document[:index][:_id] }
      Document.markListAsIndexed(ids)
    end

    puts "Done"
  end

  # Usage rake index:create
  desc "Create elastic search index"
  task :create => :environment do |task, args|
    # Connect to elastic client
    client = Elasticsearch::Client.new host: elastic_connection_string

    index = Index.new
    name = index.getCurrent
    mappings = index.getMappings
    settings = index.getSettings

    # Update if it exists
    if client.indices.exists? index: name
      puts "Index #{name} already exists!"

      # # Put settings
      # client.indices.put_settings index: name, body: settings
      #
      # # Delete mappings
      # oldMappings = client.indices.get_mapping index: name
      # oldTypes = oldMappings.keys
      # newTypes = mappings.keys
      # removedTypes = oldTypes - newTypes
      # removedTypes.each do |type|
      #   client.indices.delete_mapping index: name, type: type
      # end
      # if removedTypes.length > 0
      #   puts "Removing mapping types: #{removedTypes.join(", ")}"
      # end
      #
      # # Put mappings
      # mappings.each do |type, body|
      #   client.indices.put_mapping index: name, type: type, body: body
      # end

    # Otherwise create
    else
      puts "Creating index #{name}..."
      client.indices.create( index: name, body: {
        settings: settings,
        mappings: mappings
      })
      puts "Done"
    end

  end

  # Usage rake index:delete[primary]
  desc "Delete elastic search index"
  task :delete, [:name] => :environment do |task, args|
    # Connect to elastic client
    client = Elasticsearch::Client.new host: elastic_connection_string

    if args.name.present?
      puts "Deleting index #{args.name}..."
      client.indices.delete index: args.name
      puts "Done"
    else
      puts "Please enter an index name to delete"
    end
  end

  # Usage rake index:info
  # Usage rake index:info[primary]
  desc "Get elastic search index info"
  task :info, [:name] => :environment do |task, args|
    args.with_defaults(:name => Index.current)

    # Connect to elastic client
    client = Elasticsearch::Client.new host: elastic_connection_string

    info = client.indices.get index: args.name

    puts "Info for index #{args.name}:"
    puts info.inspect
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
    index_name = Index.current
    elastic = []

    puts "#{documents.length} documents retrieved from database..."

    documents.each do |document|
      entry = {
        _index: index_name,
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

end
