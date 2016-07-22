# Oral History API

An API and set of tasks that create, build, update, and query an Elasticsearch index based on metadata and annotations from [The NYPL Community Oral History Website](http://oralhistory.nypl.org) and transcripts from [The NYPL Community Oral History Transcript Editor](http://transcribe.oralhistory.nypl.org/)

## Requirements

* [Ruby](https://www.ruby-lang.org/en/) - developed using version 2.3.0
* [PostgreSQL](https://www.postgresql.org/) - developed using version 9.4.3
* [Elasticsearch](https://www.elastic.co/) - developed on [Elastic Cloud](https://www.elastic.co/cloud)

## Configure Your Project

1. Create `config/database.yml` based on [config/database.sample.yml](config/database.sample.yml) - update this file with your own database credentials
2. Create `config/application.yml` based on [config/application.sample.yml](config/application.sample.yml) - this file contains all your private config credentials for services like Elasticsearch.
  - Fill out **PROTOCOL**, **ELASTIC_USER**, **ELASTIC_PASSWORD**, **ELASTIC_HOST** based on your Elasticsearch credentials
  - **INDEX_PREFIX** and **INDEX_VERSION** are used to create the name of your current index, e.g. prefix "primary" and version "v2" will create index name "primaryv2"
  - **TRANSCRIPT_EDITOR_URL** is the base URL to the [Open Transcript Editor](https://github.com/NYPL/transcript-editor) instance

## Setup and run the app

1. Run `bundle` - this will install all the necessary gems for this app
2. Run `rake db:setup` to setup the database based on `config/database.yml`
3. Run rake tasks to ingest data to be indexed. You may run these any number of times. By default, it will only pull documents updated or created after the last ingest task.
  - `rake oralhistory:ingest` - Ingests data from [oralhistory.nypl.org](http://oralhistory.nypl.org) and stores in database
  - `rake transcripteditor:ingest` - Ingests data from the `TRANSCRIPT_EDITOR_URL` in your config and stores in database
4. Run rake tasks for creating and building the search index.
  - `rake index:create` - Creates index based on [configuration](app/models/index.rb)
  - Confirm index was created by running `rake index:info`
  - `rake index:build` - Builds the index based on the data ingested in step 3. You may run this any number of times. By default, it will only pull documents updated or created after the last index build task.
4. Run `rails s` to start your server. Go to [http://localhost:3000/search?q=new+york](http://localhost:3000/search?q=new+york) to see sample results

## Reindexing

You only need to reindex if you change the index mappings or settings. You can add and update documents incrementally without reindexing

1. Note the name of the current index by running `rake index:info`
2. Update the `INDEX_VERSION` in your `./config/application.yml` in development
3. Create the new index `rake index:create`
4. Re-build the index `rake index:build[500,rebuild]`
5. Confirm new index info `rake index:info`
6. Run `figaro heroku:set -e production` to update the new `INDEX_VERSION` in production
7. Confirm your new index works in production
8. Delete the old index `rake index:delete[old-index-name]`
