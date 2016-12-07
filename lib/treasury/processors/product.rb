# coding: utf-8
module Treasury
  module Processors
    module Product
      extend ActiveSupport::Concern

      included do
        alias_method :product_id=, :object=
        alias_method :product_id, :object
      end

      protected

      def init_event_params
        self.product_id = extract_product
        raise ArgumentError, "Product ID expected to be Integer, #{@event.inspect}" unless product_id
      end

      def extract_product
        @event.raw_data[:product_id] || @event.fetch(:id)
      end
    end
  end
end
