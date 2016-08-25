module Oralhistory

  def oh_get_annotation_data(obj, parent_id)
    id = "#{parent_id}_ann_#{obj["start"]}_#{obj["end"]}"
    entry = {doc_type: "annotation", doc_uid: id, doc_parent: parent_id, doc_data: ""}

    attributes = [
      {name: "start", type: "integer"},
      {name: "end", type: "integer"},
      {name: "text", type: "string", required: true}
    ]
    data = parse_attributes(obj, attributes)
    if data
      # convert to milliseconds
      data["start"] = data["start"] * 1000 if data["start"]
      data["end"] = data["end"] * 1000 if data["end"]
      entry[:doc_data] = data.to_json
    else
      entry = false
    end

    entry
  end

  def oh_get_item_data(url)
    resp = json_request(url)
    return false unless resp

    data = []
    attributes = [
      {name: "interviewer_name", type: "string"},
      {name: "storyteller_name", type: "string", map_to: "title"},
      {name: "summary", type: "string", map_to: "description"},
      {name: "place_of_birth", type: "string"},
      {name: "url", type: "string", map_to: "audio_url"},
      {name: "image.thumb.url", type: "string", map_to: "image_url"},
      {name: "date_of_birth", type: "date"},
      {name: "neighborhood.slug", type: "string", map_to: "collection_id"},
      {name: "neighborhood.title", type: "string", map_to: "collection_title"},
      {name: "neighborhood.subtitle", type: "string", map_to: "collection_subtitle"}
    ]
    item_id = resp["slug"]

    # build item data
    item_entry = {doc_type: "item", doc_uid: item_id, doc_data: ""}
    item_data = parse_attributes(resp, attributes)
    if item_data
      item_entry[:doc_data] = item_data.to_json
      data << item_entry
    end

    # build annotation data
    if resp.key?("annotations") && !resp["annotations"].blank?
      annotations = JSON.parse(resp["annotations"])
      annotations.each do |annotation|
        annotation_entry = oh_get_annotation_data(annotation, item_id)
        data << annotation_entry if annotation_entry
      end
    end

    data
  end

  def oh_get_items(source, updated_after)
    date = IngestItem.getLastDate(source)
    date = updated_after.to_datetime if updated_after
    json_request("http://oralhistory.nypl.org/interviews.json?updated_after=#{date.strftime("%Y-%m-%d")}")
  end

end
