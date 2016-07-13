require 'net/http'
require 'json'

namespace :oralhistory do

  # Usage rake oralhistory:get_items
  desc "Get items and annotations from oralhistory.nypl.org"
  task :get_items => :environment do |task, args|

    # Retrieve all the items after last indexed date
    last_indexed_date = Item.getLastIndexedDate
    items = json_request("http://oralhistory.nypl.org/interviews.json?updated_after=#{last_indexed_date.strftime("%Y-%m-%d")}")

    # Download and save each item
    items.each do |item|
      itemData = get_item_data(item["url"])
      itemData.each do |entry|
        Item.saveEntry(entry)
      end
    end

  end

  def parse_attributes(obj, attributes)
    data = {}
    valid = true
    attributes.each do |attr|
      # get value
      value = ""
      # nested object
      parts = attr[:name].split('.')
      parts.each do |part|
        if value.empty? && obj.key?(part)
          value = obj[part]
        elsif value.key?(part)
          value = value[part]
        end
      end
      # set if value not empty
      unless value.empty? || value.nil?
        key = attr[:name]
        key = attr[:map_to] if attr.key?(:map_to)
        data[key] = value
      end
      if (value.empty? || value.nil?) && attr.key?(:required)
        valid = false
      end
    end
    data = false unless valid
    data
  end

  def get_annotation_data(obj, parent_id)
    id = "#{parent_id}_#{obj["start"]}_#{obj["end"]}"
    entry = {index: "annotations", type: "annotation", uid: id, parent: parent_id, data: ""}

    attributes = [
      {name: "start", type: "integer"},
      {name: "end", type: "integer"},
      {name: "text", type: "string", required: true}
    ]
    data = parse_attributes(obj, attributes)
    if data
      entry[:data] = data.to_json
    else
      entry = false
    end

    entry
  end

  def get_item_data(url)
    resp = json_request(url)
    return false unless resp

    data = []
    attributes = [
      {name: "interviewer_name", type: "string"},
      {name: "storyteller_name", type: "string"},
      {name: "summary", type: "string"},
      {name: "place_of_birth", type: "string"},
      {name: "url", type: "string", map_to: "audio_url"},
      {name: "image.url", type: "string", map_to: "image_url"},
      {name: "image.thumb.url", type: "string", map_to: "thumb_url"},
      {name: "date_of_birth", type: "date"},
      {name: "neighborhood.slug", type: "string", map_to: "collection_id"},
      {name: "neighborhood.title", type: "string", map_to: "collection_title"},
      {name: "neighborhood.subtitle", type: "string", map_to: "collection_subtitle"}
    ]
    item_id = resp["slug"]

    # build item data
    item_entry = {index: "items", type: "item", uid: item_id, data: ""}
    item_data = parse_attributes(resp, attributes)
    if item_data
      # make a parent-child relation to lines and annotations
      item_data["mappings"] = {"line": {}, "annotation": {}}
      item_entry[:data] = item_data.to_json
      data << item_entry
    end

    # build annotation data
    if resp.key?("annotations") && !resp["annotations"].blank?
      annotations = JSON.parse(resp["annotations"])
      annotations.each do |annotation|
        annotation_entry = get_annotation_data(annotation, item_id)
        data << annotation_entry if annotation_entry
      end
    end

    data
  end

  def json_request(url)
    puts "GET #{url}"
    uri = URI(url)
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end

end
