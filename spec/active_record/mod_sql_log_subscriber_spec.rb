# frozen_string_literal: true

require_relative '../spec_helper'

require 'logger'
require 'active_record/type'
require 'active_record/relation/query_attribute'
require 'active_record/mod_sql_log_subscriber'

::RSpec.describe ::ActiveRecord::ModSqlLogSubscriber do
  let(:logger) { instance_double(::Logger, info: nil) }
  let(:subscriber) { ::ActiveRecord::ModSqlLogSubscriber.new }

  before do
    ::ActiveRecord::Base.logger = logger
  end

  after do
    ::ActiveRecord::Base.logger = nil
  end

  def to_event(payload)
    payload[:name] ||= 'SQL'
    ::ActiveSupport::Notifications::Event.new('test', ::Time.now, ::Time.now, 1, payload)
  end

  describe '#sql' do
    context 'with SELECT sql' do
      it 'does not write log' do
        sql = "SELECT * FROM users"

        subscriber.sql(to_event(sql: sql))

        expect(logger).not_to have_received(:info)
      end
    end

    context 'with INSERT sql' do
      it 'writes log' do
        sql = "INSERT INTO users VALUES ($1, $2)"
        binds = [
          ::ActiveRecord::Relation::QueryAttribute.new(:id, 1, ::ActiveModel::Type::Integer.new),
          ::ActiveRecord::Relation::QueryAttribute.new(:name, 'Name',
                                                       ::ActiveModel::Type::String.new),
        ]
        type_casted_binds = binds.map(&:value)

        subscriber.sql(to_event(sql: sql, binds: binds, type_casted_binds: type_casted_binds))

        expect(logger).to have_received(:info)
      end
    end

    context 'with UPDATE sql' do
      it 'writes log' do
        sql = "UPDATE users SET name = $1 WHERE id = $2"
        binds = [
          ::ActiveRecord::Relation::QueryAttribute.new(:name, 'New name',
                                                       ::ActiveModel::Type::String.new),
          ::ActiveRecord::Relation::QueryAttribute.new(:id, 1, ::ActiveModel::Type::Integer.new),
        ]
        type_casted_binds = binds.map(&:value)

        subscriber.sql(to_event(sql: sql, binds: binds, type_casted_binds: type_casted_binds))

        expect(logger).to have_received(:info)
      end
    end

    context 'with DELETE sql' do
      it 'writes log' do
        sql = "DELETE FROM users WHERE id = $1"
        binds = [
          ::ActiveRecord::Relation::QueryAttribute.new(:id, 1, ::ActiveModel::Type::Integer.new),
        ]
        type_casted_binds = binds.map(&:value)

        subscriber.sql(to_event(sql: sql, binds: binds, type_casted_binds: type_casted_binds))

        expect(logger).to have_received(:info)
      end
    end

    context 'with TRUNCATE sql' do
      it 'writes log' do
        sql = "TRUNCATE users"

        subscriber.sql(to_event(sql: sql))

        expect(logger).to have_received(:info)
      end
    end

    context 'with BEGIN sql' do
      it 'writes log' do
        sql = "BEGIN"

        subscriber.sql(to_event(sql: sql))

        expect(logger).to have_received(:info)
      end
    end

    context 'with COMMIT sql' do
      it 'writes log' do
        sql = "COMMIT"

        subscriber.sql(to_event(sql: sql))

        expect(logger).to have_received(:info)
      end
    end

    context 'with ROLLBACK sql' do
      it 'writes log' do
        sql = "ROLLBACK"

        subscriber.sql(to_event(sql: sql))

        expect(logger).to have_received(:info)
      end
    end

    context 'when disable is true' do
      before do
        subscriber.disable = true
      end

      it 'does not write log' do
        sql = "DELETE FROM users"

        subscriber.sql(to_event(sql: sql))

        expect(logger).not_to have_received(:info)
      end
    end

    context 'when sql is nil' do
      it 'does not write log' do
        sql = nil

        subscriber.sql(to_event(sql: sql))

        expect(logger).not_to have_received(:info)
      end
    end

    context 'when cached is true' do
      it 'does not write log' do
        sql = "DELETE FROM users"

        subscriber.sql(to_event(sql: sql, cached: true))

        expect(logger).not_to have_received(:info)
      end
    end

    context 'when payload name is ignore' do
      it 'does not write log' do
        sql = "DELETE FROM users"

        subscriber.sql(to_event(sql: sql, name: 'EXPLAIN'))

        expect(logger).not_to have_received(:info)
      end
    end

    describe 'log_format' do
      before do
        ::ActiveRecord::ModSqlLogSubscriber.log_format = log_format
      end

      context 'with :text format' do
        let(:log_format) { :text }

        it 'writes text formatted log' do
          sql = "DELETE FROM users WHERE id = $1"
          binds = [
            ::ActiveRecord::Relation::QueryAttribute.new(:id, 1, ::ActiveModel::Type::Integer.new),
          ]
          type_casted_binds = binds.map(&:value)

          subscriber.sql(to_event(sql: sql, binds: binds, type_casted_binds: type_casted_binds))

          expect(logger).to have_received(:info)
                              .with('DELETE FROM users WHERE id = $1  {:id=>1}')
        end
      end

      context 'with :json format' do
        let(:log_format) { :json }

        it 'writes json formatted log' do
          sql = "DELETE FROM users WHERE id = $1"
          binds = [
            ::ActiveRecord::Relation::QueryAttribute.new(:id, 1, ::ActiveModel::Type::Integer.new),
          ]
          type_casted_binds = binds.map(&:value)

          subscriber.sql(to_event(sql: sql, binds: binds, type_casted_binds: type_casted_binds))

          expect(logger).to have_received(:info)
                              .with('{"sql":"DELETE FROM users WHERE id = $1","binds":{"id":1}}')
        end
      end

      context 'with :hash format' do
        let(:log_format) { :hash }

        it 'writes hash formatted log' do
          sql = "DELETE FROM users WHERE id = $1"
          binds = [
            ::ActiveRecord::Relation::QueryAttribute.new(:id, 1, ::ActiveModel::Type::Integer.new),
          ]
          type_casted_binds = binds.map(&:value)

          subscriber.sql(to_event(sql: sql, binds: binds, type_casted_binds: type_casted_binds))

          expect(logger).to have_received(:info).with({ sql: sql, binds: { id: 1 } })
        end
      end

      context 'with custom proc format' do
        let(:log_format) { ->(sql, binds) { 'custom proc' } }

        it 'writes custom proc formatted log' do
          sql = "DELETE FROM users WHERE id = $1"
          binds = [
            ::ActiveRecord::Relation::QueryAttribute.new(:id, 1, ::ActiveModel::Type::Integer.new),
          ]
          type_casted_binds = binds.map(&:value)

          subscriber.sql(to_event(sql: sql, binds: binds, type_casted_binds: type_casted_binds))

          expect(logger).to have_received(:info).with('custom proc')
        end
      end

      context 'with unexpected format' do
        let(:log_format) { :unexpected }

        it 'raises error' do
          expect { subscriber.sql(to_event(sql: 'INSERT')) }.to raise_error(::StandardError)
        end
      end
    end
  end
end
