module Treasury
  module Pgq
    class Snapshot
      # represents a PostgreSQL snapshot.
      # http://www.postgresql.org/docs/8.3/static/functions-info.html#FUNCTIONS-TXID-SNAPSHOT-PARTS
      # http://skytools.projects.postgresql.org/txid/functions-txid.html

      # example:
      # >>> sn = Snapshot.new('11:20:11,12,15')
      # >>> sn.contains?(9)
      # True
      # >>> sn.contains?(11)
      # False
      # >>> sn.contains?(17)
      # True
      # >>> sn.contains?(20)
      # False

      attr_reader :as_string
      attr_reader :xmin
      attr_reader :xmax
      attr_reader :txid_list

      def initialize(string_snapshot)
        # create snapshot from string
        @as_string = string_snapshot
        parts = string_snapshot.split(':')
        raise 'Unknown format for snapshot' unless (2..3).include?(parts.size)
        @xmin = parts[0].to_i
        @xmax = parts[1].to_i
        @txid_list = []
        return if parts[2].blank?
        @txid_list = parts[2].split(',').map(&:to_i)
      end

      def contains?(txid)
        # is txid visible in snapshot
        txid = txid.to_i
        if txid < xmin
          return true
        elsif txid >= xmax
          return false
        elsif txid_list.include?(txid)
          return false
        end

        true
      end
    end
  end
end
