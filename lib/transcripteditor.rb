module Transcripteditor

  def te_get_item_data(resp)
    data = []
    attributes = [
      {name: "title", type: "string"},
      {name: "description", type: "string"},
      {name: "audio_url", type: "string"},
      {name: "image_url", type: "string"},
      {name: "duration", type: "integer"}
    ]
    item_id = resp["id"]

    # build item data
    item_entry = {doc_type: "item", doc_uid: item_id, doc_data: ""}
    item_data = parse_attributes(resp, attributes)
    if item_data
      item_entry[:doc_data] = item_data.to_json
      data << item_entry
    end

    data
  end

  def te_get_item_json(url)
    resp = json_request(url)
    return false unless resp
    resp
  end

  def te_get_items(source, updated_after)
    # Retrieve all the items after last indexed date
    date = IngestItem.getLastDate(source)
    date = updated_after.to_datetime if updated_after
    resp = json_request("#{ENV['TRANSCRIPT_EDITOR_URL']}/transcript_files.json?updated_after=#{date.strftime("%Y-%m-%d")}")
    # TODO: handle pagination
    resp["entries"]
  end

  def te_get_line_data(resp)
    data = []
    attributes = [
      {name: "original_text", type: "string"},
      {name: "best_text", type: "string"},
      {name: "start_time", type: "integer", map_to: "start"},
      {name: "end_time", type: "integer", map_to: "end"}
    ]
    item_id = resp["id"]

    # get lines
    lines = resp["lines"]
    lines.each do |line|
      # build line data
      # line_id = line["id"]
      line_id = "#{item_id}_line_#{line["sequence"]}"
      line_entry = {doc_type: "line", doc_parent: item_id, doc_uid: line_id, doc_data: ""}
      line_data = parse_attributes(line, attributes)
      if line_data
        line_entry[:doc_data] = line_data.to_json
        data << line_entry
      end
    end

    data
  end

end
