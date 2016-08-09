desc "This task is called by the Heroku scheduler add-on"
task :update => :environment do
  Rake::Task["oralhistory:ingest"].reenable
  Rake::Task["oralhistory:ingest"].invoke
  Rake::Task["transcripteditor:ingest"].reenable
  Rake::Task["transcripteditor:ingest"].invoke
  Rake::Task["index:build"].reenable
  Rake::Task["index:build"].invoke
end
