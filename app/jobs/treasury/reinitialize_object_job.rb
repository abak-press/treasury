module Treasury
  class ReinitializeObjectJob
    include Resque::Integration
    queue :base
    unique

    def self.execute(field_name, object_id)
      field_name.constantize.reinitialize_object(object_id)
    end
  end
end
