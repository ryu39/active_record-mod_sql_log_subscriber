# frozen_string_literal: true

require 'json'
require 'active_support/configurable'
require 'active_support/log_subscriber'
require 'active_record'
require 'active_record/log_subscriber'

module ActiveRecord
  class ModSqlLogSubscriber < ::ActiveRecord::LogSubscriber
    include ActiveSupport::Configurable

    VERSION = "0.1.1"

    config_accessor :disable, :log_level, :log_format, :target_statements

    # Default values
    self.disable = false
    self.log_level = :info
    self.log_format = :text
    self.target_statements = %w(insert update delete truncate begin commit rollback savepoint release\ savepoint)

    def sql(event)
      return if self.disable

      payload = event.payload
      sql = payload[:sql]

      return if sql.nil?
      return if payload[:cached]
      return if IGNORE_PAYLOAD_NAMES.include?(payload[:name])
      return unless target_sql_checker.match?(sql)

      binds = type_casted_binds(payload[:type_casted_binds])
      send(self.log_level, formatter.call(sql, binds))
    end

    private

    def target_sql_checker
      @target_sql_checker ||= /\A\s*(#{self.target_statements.join('|')})/mi
    end

    def formatter
      @formatter ||=
        case self.log_format
        when :text
          ->(sql, binds) { binds.empty? ? sql : "#{sql}  #{binds.inspect}" }
        when :json
          -> (sql, binds) { ::JSON.generate(sql: sql, binds: binds) }
        when :hash
          -> (sql, binds) { { sql: sql, binds: binds } }
        when ::Proc
          self.log_format
        else
          raise "Unexpected log format: #{self.log_format}"
        end
    end
  end
end
