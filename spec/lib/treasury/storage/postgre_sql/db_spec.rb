# frozen_string_literal: true

RSpec.describe Treasury::Storage::PostgreSQL::Db do
  let(:storage_params) do
    {
      table: 'test_table',
      key: 'object_id',
      key_type: :integer,
      fields: {field1: {type: :integer}, field2: {type: :varchar}}
    }
  end
  let(:storage) { described_class.new(storage_params) }
  let(:connection) { ActiveRecord::Base.connection }

  before do
    allow(storage).to receive(:connection).and_return(connection)
  end

  describe '#lock' do
    before do
      allow(connection).to receive(:execute)
    end

    context 'when not shared, e.g. has exclusize access' do
      before do
        allow(storage).to receive(:shared?).and_return false
      end

      it do
        expect(connection).not_to receive(:execute).with('LOCK TABLE "test_table" IN SHARE MODE')
        storage.lock
      end
    end

    context 'when shared' do
      it do
        expect(connection).to receive(:execute).ordered.with('LOCK TABLE "test_table" IN SHARE MODE')
        expect { storage.lock }.not_to raise_error
      end
    end
  end

  describe '#bulk_write' do
    let(:chomp_sql) { ->(text) { text.gsub(/[\s\n]+/, '') } }
    let(:sql_for_update) do
      ->(fields_list, values) do
        fields = []
        fields_with_type = []
        fields_sources = []

        if fields_list.include?(:field1)
          fields << 'field1'
          fields_with_type << 'field1::integer'
          fields_sources << 'field1 = source.field1'
        end

        if fields_list.include?(:field2)
          fields << 'field2'
          fields_with_type << 'field2::varchar'
          fields_sources << 'field2 = source.field2'
        end

        chomp_sql.call(<<-SQL)
          WITH source AS (
            SELECT object_id::integer , #{fields_with_type.join(',')}
            FROM (VALUES #{values}) t (object_id, #{fields.join(',')})
          ),
          updated AS (
            UPDATE "test_table" target
            SET #{fields_sources.join(',')}
            FROM source
            WHERE target.object_id = source.object_id
            RETURNING target.*
          )
          INSERT INTO "test_table" (object_id, #{fields.join(',')})
          SELECT object_id, #{fields.join(',')}
          FROM source
          WHERE NOT EXISTS (
          SELECT 1
            FROM updated target
            WHERE target.object_id = source.object_id
          )
        SQL
      end
    end

    context 'when rows size less then treashold' do
      let(:data_rows) { {56 => {field1: '1', field2: '2'}, 7 => {field1: '17'}, 33 => {field2: '3'}, 14 => nil} }

      it do
        expect(connection).to receive(:execute) do |sql|
          expect(chomp_sql.call(sql)).to eq(sql_for_update.call([:field1, :field2], "(56, '1', '2')"))
        end

        expect(connection).to receive(:execute) do |sql|
          expect(chomp_sql.call(sql)).to eq(sql_for_update.call([:field1], "(7, '17')"))
        end

        expect(connection).to receive(:execute) do |sql|
          expect(chomp_sql.call(sql)).to eq(sql_for_update.call([:field2], "(33, '3')"))
        end

        expect(connection).to receive(:update) do |sql|
          expect(chomp_sql.call(sql)).to eq(chomp_sql.call(<<-SQL))
            DELETE FROM "test_table" WHERE object_id IN (14)
          SQL
        end
      end
    end

    context 'when rows size more then treashold' do
      let(:data_rows) do
        {
          56 => {field1: '1', field2: '2'},
          7 => {field1: '17'},
          33 => {field2: '3'},
          14 => nil,
          15 => {field1: '10', field2: '20'},
          51 => {field1: '11', field2: '21'},
          111 => {field1: '2'},
          88 => {field1: '51'},
          3 => nil,
          67 => nil
        }
      end

      it do
        expect(connection).to receive(:update) do |sql|
          expect(chomp_sql.call(sql)).to eq(chomp_sql.call(<<-SQL))
            DELETE FROM "test_table" WHERE object_id IN (14, 3, 67)
          SQL
        end

        expect(connection).to receive(:execute) do |sql|
          values = "(56, '1', '2'), (15, '10', '20'), (51, '11', '21')"
          expect(chomp_sql.call(sql)).to eq(sql_for_update.call([:field1, :field2], values))
        end

        expect(connection).to receive(:execute) do |sql|
          values = "(7, '17'), (111, '2'), (88, '51')"
          expect(chomp_sql.call(sql)).to eq(sql_for_update.call([:field1], values))
        end

        expect(connection).to receive(:execute) do |sql|
          expect(chomp_sql.call(sql)).to eq(sql_for_update.call([:field2], "(33, '3')"))
        end
      end
    end

    after { storage.bulk_write(data_rows) }
  end
end
