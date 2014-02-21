# vim: set ft=ruby:
require 'guard/guard'
require 'guard/rake'

guard 'rake', :task => 'test:quick' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end
