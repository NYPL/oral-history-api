class DocumentsController < ApplicationController

  def index
    @resp = Document.limit(500)
    render :json => @resp
  end

  def search
    @results = nil
    client = Elasticsearch::Client.new host: elastic_connection_string
    index = Index.new

    # Get query filters
    query = params[:q]
    filters = nil
    filters = params[:filters].to_unsafe_h if params[:filters].present?
    puts "Query string: #{query}"
    puts "Filters #{filters.inspect}"

    # Do query
    queryBody = index.getSearchBody(query, filters)
    # puts queryBody.inspect

    @results = client.search index: index.getDefaultName, type: 'item', body: queryBody

    render :json => @results
  end

  def show
    @resp = Document.where(doc_uid: params[:id]).first
    render :json => @resp
  end

end
