module Treasury
  class InitializeFieldJob < BaseJob
    acts_as_singleton [:field_class]

    def execute
      field = Treasury::Fields::Base.create_by_class(params[:field_class])
      field.initialize!
    end

    def title
      "#{self.class.name.underscore.gsub('_job', '')}: #{params[:field_class]}"
    end
  end
end
