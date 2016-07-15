class DocumentsController < ApplicationController

  def index
    @resp = Documents.limit(100)
    render :json => @resp
  end

  def search
    client = Elasticsearch::Client.new host: elastic_connection_string

    @resp = client.search q: 'new york'
    render :json => @resp
  end

  def show
    @resp = Document.where(doc_uid: params[:id]).first
    render :json => @resp
  end

end
