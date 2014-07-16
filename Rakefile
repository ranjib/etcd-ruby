require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rdoc/task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new("spec")

RuboCop::RakeTask.new do |task|
  task.fail_on_error = true
end

RDoc::Task.new do |rdoc|
  rdoc.main = "README.rdoc"
  rdoc.rdoc_files.include("lib   /*.rb")
end

namespace :test do
  desc 'Run all of the quick tests.'
  task :quick do
    Rake::Task['rubocop'].invoke
    Rake::Task['spec'].invoke
  end
end
