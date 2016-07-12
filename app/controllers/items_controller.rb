class ItemsController < ApplicationController

  def index
    @resp = []
  end

  def search
    client = Elasticsearch::Client.new host: elastic_connection_string

    @resp = client.search q: 'test'
    render :json => @resp
  end

  def show
    @resp = {}
  end

end
