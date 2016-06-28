module Treasury
  module Migration
    # Helper for create new denormalization field.
    #
    # Example:
    #
    #  class AddCompanyFaceTranslator < ActiveRecord::Migration
    #    include Treasury::Migration::NewField
    #
    #     def group
    #       :company
    #     end
    #
    #     def worker
    #       :common
    #     end
    #
    #     def field
    #       {
    #         class: 'CompanyTreasury::CompanyFace::Field',
    #         storage: [:redis, {key: :companies}],
    #         fields: {
    #           representative_user_id: {type: :integer},
    #           contact_user_id: {type: :integer}
    #         }
    #       }
    #     end
    #
    #     def processor
    #       {
    #         class: 'CompanyTreasury::CompanyFace::Processor',
    #         table_name: 'company_faces',
    #         trigger: {include: 'company_id, representative_user_id, contact_user_id'}
    #       }
    #     end
    #   end
    module NewField
      def up
        return if Rails.env.test?

        create_denormalization_field
      end

      def down
        return if Rails.env.test?

        delete_denormalization_field
      end

      private

      def create_denormalization_field
        Denormalization::Models::Field.transaction do
          field_record = Denormalization::Models::Field.create! do |f|
            f.title = field[:title] || field[:class].underscore.tr('/', '_')
            f.group = group
            f.field_class = field[:class]
            f.active = true
            f.worker = find_or_create_worker
            f.params = {fields: field[:fields]}
            f.storage = [
              {
                class: storage(field[:storage].first),
                params: field[:storage].last
              }
            ]
            f.oid = 0
          end

          queue = Denormalization::Models::Queue.create! do |q|
            q.name = consumer_name
            q.table_name = processor[:table_name]
            q.db_link_class = processor[:db_link_class]
            q.trigger_code = q.generate_trigger(processor[:trigger])
          end

          Denormalization::Models::Processor.create! do |f|
            f.field = field_record
            f.queue = queue
            f.processor_class = processor[:class]
            f.consumer_name = consumer_name
            f.oid = 0
            f.params = nil
          end
        end
      end

      def delete_denormalization_field
        return if Rails.env.test?

        Denormalization::Models::Processor.find_by_consumer_name(consumer_name).try(:destroy)
        Denormalization::Models::Queue.find_by_name(consumer_name).try(:destroy)
        Denormalization::Models::Field.find_by_field_class(field[:class]).try(:destroy)
      end

      def find_or_create_worker
        worker = respond_to?(:worker) ? worker : :common

        Denormalization::Models::Worker.find_by_name(worker) ||
          Denormalization::Models::Worker.create!(name: worker, active: true)
      end

      def consumer_name
        processor[:title] || processor[:class].underscore.tr('/', '_')
      end

      def storage(name)
        case name
        when :redis
          'CoreDenormalization::Storage::Redis::Multi'
        when :db
          'CoreDenormalization::Storage::PostgreSQL::Db'
        when :pgq
          'CoreDenormalization::Storage::PostgreSQL::PgqProducer'
        else
          raise 'Unexpected storage'
        end
      end
    end
  end
end
