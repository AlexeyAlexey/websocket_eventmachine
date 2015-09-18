require 'rubygems'
require 'bundler'
require 'active_record'
require 'json'
Bundler.require(:default)

Dir[File.dirname(__FILE__) + '/initializers/*.rb'].each {|file| require file }