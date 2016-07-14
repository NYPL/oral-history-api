module Util

  require 'net/http'
  require 'json'

  def parse_attributes(obj, attributes)
    data = {}
    valid = true
    attributes.each do |attr|
      # get value
      value = ""
      # nested object
      parts = attr[:name].split('.')
      parts.each do |part|
        if value=="" && obj.key?(part)
          value = obj[part]
        elsif value.key?(part)
          value = value[part]
        end
      end
      # set if value not empty
      if value.present?
        key = attr[:name]
        key = attr[:map_to] if attr.key?(:map_to)
        data[key] = value
      elsif attr.key?(:required)
        valid = false
      end
    end
    data = false unless valid
    data
  end

  def json_request(url)
    puts "GET #{url}"
    uri = URI(url)
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end

end
