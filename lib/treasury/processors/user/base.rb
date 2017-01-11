# coding: utf-8

module Treasury
  module Processors
    module User
      class Base < ::Treasury::Processors::Base
        alias :user_id= :object=
        alias :user_id  :object

        protected

        def init_event_params
          self.user_id = extract_user
          raise ArgumentError, "User ID expected to be Integer, #{@event.inspect}" unless user_id
        end

        def extract_user
          @event.raw_data[:user_id] || @event.raw_data[:id]
        end
      end
    end
  end
end
