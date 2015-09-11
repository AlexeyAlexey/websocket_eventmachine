require 'rubygems'
require 'bundler'
Bundler.require(:default)

Dir[File.dirname(__FILE__) + '/initializers/*.rb'].each {|file| require file }