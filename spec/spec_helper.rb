# encoding: utf-8

require 'simplecov'

SimpleCov.start do
  add_filter "/.bundle/"
  add_filter "/spec/"
end

$:.unshift(File.expand_path("../lib", __FILE__))
$:.unshift(File.expand_path("../spec", __FILE__))

require 'etcd'
