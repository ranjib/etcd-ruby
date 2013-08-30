require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rdoc/task"

RSpec::Core::RakeTask.new("spec")

RDoc::Task.new do |rdoc|
  rdoc.main = "README.rdoc"
  rdoc.rdoc_files.include("lib   /*.rb")
end
