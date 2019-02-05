# frozen_string_literal: true

require 'erb'
require 'yaml'
require 'active_record'

config_file = File.expand_path('../../config/database.yml', __FILE__)
config = YAML.load(ERB.new(IO.read(config_file)).result)['db']

ActiveRecord::Base.establish_connection(config)
