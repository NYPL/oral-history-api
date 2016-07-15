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

      },
      line: {
        _parent: { type: "item" }
      },
      annotation: {
        _parent: { type: "item" }
      }
    }
  end

  def getSettings
    {
      analysis: {
        filter: {
          ngram: {
            type: 'nGram',
            min_gram: 3,
            max_gram: 25
          }
        },
        analyzer: {
          ngram: {
            tokenizer: 'standard',
            filter: ['lowercase', 'asciifolding', 'ngram'],
            type: 'custom'
          },
          ngram_search: {
            tokenizer: 'standard',
            filter: ['lowercase', 'asciifolding'],
            type: 'custom'
          }
        }
      }
    }
  end

  def nGram
    {
      type: 'string',
      index_analyzer: 'ngram',
      search_analyzer: 'ngram_search'
    }
  end

end
