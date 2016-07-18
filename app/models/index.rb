class Index

  def self.defaultName
    ENV['INDEX_NAME'] || 'primary'
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
