class Index

  def self.defaultName
    ENV['INDEX_NAME'] || 'primary'
  end

  def self.validFilters
    ["collection_id"]
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
              has_child: { type: "annotation", query: { match: { text: query } }, inner_hits: {} }
            },{
              has_child: { type: "line", query: { match: { best_text: query } }, inner_hits: {} }
            },{
              has_child: { type: "line", query: { match: { original_text: query } }, inner_hits: { name: "original_line" } }
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

  def getDefaultName
    Index.defaultName
  end

  def getMappings
    {
      item: {
        properties: {
          title: { type: "string", analyzer: "transcript_analyzer" },
          description: { type: "string", analyzer: "transcript_analyzer" },
          collection_id: { type: "string" },
          collection_title: { type: "string" },
          collection_subtitle: { type: "string" },
          place_of_birth: { type: "string" },
          date_of_birth: { type: "date" },
          audio_url: { type: "string" },
          image_url: { type: "string" },
          duration: { type: "integer" }
        }
      },
      line: {
        _parent: { type: "item" },
        properties: {
          start: { type: "integer" },
          end: { type: "integer" },
          original_text: { type: "string", analyzer: "transcript_analyzer" },
          best_text: { type: "string", analyzer: "transcript_analyzer" }
        }
      },
      annotation: {
        _parent: { type: "item" },
        properties: {
          start: { type: "integer" },
          end: { type: "integer" },
          text: { type: "string", analyzer: "transcript_analyzer" }
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
