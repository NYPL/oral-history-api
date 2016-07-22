class Index

  def self.current
    "#{Index.name}#{Index.version}"
  end

  def self.name
    ENV['INDEX_PREFIX'] || 'primary'
  end

  def self.validFilters
    ["collection_id"]
  end

  def self.version
    ENV['INDEX_VERSION'] || ''
  end

  def getFilters(f)
    filters = []
    valid_filters = Index.validFilters
    if f.present?
      valid_filters.each do |valid_filter_key|
        if f.key?(valid_filter_key) && !f[valid_filter_key].blank?
          filter = { term: {} }
          filter[:term][:"#{valid_filter_key}"] = f[valid_filter_key]
          filters << filter
        end
      end
    end
    filters
  end

  def getQuery(q)
    query = ""
    if q.present?
      # Add fuzzy search to query
      ngrams = q.gsub(/\s+/m, ' ').strip.split(" ")
      ngrams = ngrams.map { |n| "#{n}~" }
      query = ngrams.join(" ")
    end
    query
  end

  def getSearchBody(q, filters=nil)
    query = getQuery(q)
    filters = getFilters(filters)

    # build query body
    body = {
      query: {
        bool: {
          should: [
            {
              match: { title: query }
            },{
              match: { description: query }
            },{
              has_child: { type: "annotation", query: { match: { text: query } }, inner_hits: { highlight: { fields: { text: {} } } } }
            },{
              has_child: { type: "line", query: { match: { best_text: query } }, inner_hits: { highlight: { fields: { best_text: {} } } } }
            },{
              has_child: { type: "line", query: { match: { original_text: query } }, inner_hits: { name: "original_line", highlight: { fields: { original_text: {} } } } }
            }
          ]
        }
      }
    }

    # Add filters
    if filters.length > 0
      body[:query][:bool][:filter] = filters
    end

    body
  end

  def getCurrent
    Index.current
  end

  def getMappings
    {
      item: {
        properties: {
          title: { type: "string", analyzer: "transcript_analyzer" },
          description: { type: "string", analyzer: "transcript_analyzer" },
          collection_id: { type: "string", index: "not_analyzed" },
          collection_title: { type: "string", index: "no" },
          collection_subtitle: { type: "string", index: "no" },
          place_of_birth: { type: "string" },
          date_of_birth: { type: "date" },
          audio_url: { type: "string", index: "no" },
          image_url: { type: "string", index: "no" },
          duration: { type: "integer" }
        }
      },
      line: {
        _parent: { type: "item" },
        properties: {
          start: { type: "integer" },
          end: { type: "integer" },
          original_text: { type: "string", analyzer: "transcript_analyzer", index_options: "offsets" },
          best_text: { type: "string", analyzer: "transcript_analyzer", index_options: "offsets" }
        }
      },
      annotation: {
        _parent: { type: "item" },
        properties: {
          start: { type: "integer" },
          end: { type: "integer" },
          text: { type: "string", analyzer: "transcript_analyzer", index_options: "offsets" }
        }
      }
    }
  end

  def getSettings
    {
      analysis: {
        analyzer: {
          transcript_analyzer: {
            tokenizer: 'standard',
            filter: ['lowercase', 'asciifolding'],
            preserve_original: 1,
            type: 'custom'
          }
        }
      }
    }
  end

end
