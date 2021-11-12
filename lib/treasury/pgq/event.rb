# frozen_string_literal: true

module Treasury
  module Pgq
    class Event
      TYPE_INSERT = 'I'
      TYPE_UPDATE = 'U'
      TYPE_DELETE = 'D'

      PARAMS_SEPARATOR = '&'
      KV_SEPARATOR = '='
      private_constant :PARAMS_SEPARATOR, :KV_SEPARATOR

      attr_accessor :id, :type, :birth_time, :txid, :ev_data, :extra1, :extra2, :extra3, :extra4

      def initialize(pgq_tuple)
        assign(pgq_tuple) if pgq_tuple
      end

      def assign(pgq_tuple)
        @id = pgq_tuple['ev_id'].to_i
        @type = pgq_tuple['ev_type'].split(':').first
        @birth_time = pgq_tuple['ev_time'].try(:to_time)
        @txid = pgq_tuple['ev_txid']
        @ev_data = pgq_tuple['ev_data']
        @extra1 = pgq_tuple['ev_extra1']
        @extra2 = pgq_tuple['ev_extra2']
        @extra3 = pgq_tuple['ev_extra3']
        @extra4 = pgq_tuple['ev_extra4']

        @data = nil
        @prev_data = nil
        @raw_data = nil
        @raw_prev_data = nil
        @user_data = nil
      end

      def raw_data
        # мой простой вариант, быстрее ~ в 3 раза, но не делает unescape и normalize_params
        @raw_data ||= @data || simple_parse_query(@ev_data)
      end

      def raw_prev_data
        # мой простой вариант, быстрее ~ в 3 раза, но не делает unescape и normalize_params
        @raw_prev_data ||= @prev_data || simple_parse_query(@extra2)
      end

      def data
        # parse_nested_query - очень узкое место, без неё скорость возростает в 2,5 раза
        @data ||= HashWithIndifferentAccess.new(Rack::Utils.parse_nested_query(@ev_data))
      end

      def prev_data
        @prev_data ||= HashWithIndifferentAccess.new(Rack::Utils.parse_nested_query(@extra2))
      end

      def user_data
        @user_data ||= HashWithIndifferentAccess.new(Rack::Utils.parse_nested_query(@extra3))
      end

      def insert?
        @type == TYPE_INSERT
      end

      def update?
        @type == TYPE_UPDATE
      end

      def delete?
        @type == TYPE_DELETE
      end

      def data_changed?
        @ev_data != @extra2
      end

      def no_data_changed?
        !data_changed?
      end

      protected

      def simple_parse_query(query)
        return {} if query.nil?

        query.split(PARAMS_SEPARATOR).each_with_object(HashWithIndifferentAccess.new) do |item, result|
          k, v = item.split(KV_SEPARATOR)

          result[k] = v
        end
      end
    end
  end
end
