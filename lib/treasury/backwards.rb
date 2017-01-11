module CoreDenormalization
  module Models
    Field = ::Treasury::Models::Field
    Processor = ::Treasury::Models::Processor
    Queue = ::Treasury::Models::Queue
    Worker = ::Treasury::Models::Worker
  end

  module Fields
    module Company
      Base = ::Treasury::Fields::Company::Base
    end

    module User
      Base = ::Treasury::Fields::User::Base
    end

    module Product
      Base = ::Treasury::Fields::Product::Base
    end

    Base = ::Treasury::Fields::Base
    Single = ::Treasury::Fields::Single
    Translator = ::Treasury::Fields::Translator
    Delayed = ::Treasury::Fields::Delayed
    Errors = ::Treasury::Fields::Errors
    NoRequireInitialization = ::Treasury::Fields::NoRequireInitialization
  end

  module Processors
    module Company
      Base = ::Treasury::Processors::Company::Base
    end

    module User
      Base = ::Treasury::Processors::User::Base
    end

    Base = ::Treasury::Processors::Base
    Single = ::Treasury::Processors::Single
    Translator = ::Treasury::Processors::Translator
    OptimizedTranslator = ::Treasury::Processors::OptimizedTranslator
    Product = ::Treasury::Processors::Product
    Delayed = ::Treasury::Processors::Delayed
    Errors = ::Treasury::Processors::Errors
    Counter = ::Treasury::Processors::Counter
    Counters = ::Treasury::Processors::Counters
  end

  module Storage
    Base = ::Treasury::Storage::Base

    module PostgreSQL
      Base = ::Treasury::Storage::PostgreSQL::Base
      Db = ::Treasury::Storage::PostgreSQL::Db
      PgqProducer = ::Treasury::Storage::PostgreSQL::PgqProducer
    end

    module Redis
      Base = ::Treasury::Storage::Redis::Base
      Multi = ::Treasury::Storage::Redis::Multi
    end
  end

  ROOT_REDIS_KEY = ::Treasury::ROOT_REDIS_KEY
  ReinitializeObjectJob = ::Treasury::ReinitializeObjectJob
end

module Denormalization
  module Models
    Field = ::Treasury::Models::Field
    Processor = ::Treasury::Models::Processor
    Queue = ::Treasury::Models::Queue
    Worker = ::Treasury::Models::Worker
  end

  module Fields
    module Company
      Base = ::Treasury::Fields::Company::Base
    end

    module User
      Base = ::Treasury::Fields::User::Base
    end

    module Product
      Base = ::Treasury::Fields::Product::Base
    end

    Base = ::Treasury::Fields::Base
    Single = ::Treasury::Fields::Single
    Translator = ::Treasury::Fields::Translator
    Delayed = ::Treasury::Fields::Delayed
    Errors = ::Treasury::Fields::Errors
    NoRequireInitialization = ::Treasury::Fields::NoRequireInitialization
  end

  module Processors
    module Company
      Base = ::Treasury::Processors::Company::Base
    end

    module User
      Base = ::Treasury::Processors::User::Base
    end

    Base = ::Treasury::Processors::Base
    Single = ::Treasury::Processors::Single
    Translator = ::Treasury::Processors::Translator
    OptimizedTranslator = ::Treasury::Processors::OptimizedTranslator
    Product = ::Treasury::Processors::Product
    Delayed = ::Treasury::Processors::Delayed
    Errors = ::Treasury::Processors::Errors
    Counter = ::Treasury::Processors::Counter
    Counters = ::Treasury::Processors::Counters
  end

  module Storage
    Base = ::Treasury::Storage::Base

    module PostgreSQL
      Base = ::Treasury::Storage::PostgreSQL::Base
      Db = ::Treasury::Storage::PostgreSQL::Db
      PgqProducer = ::Treasury::Storage::PostgreSQL::PgqProducer
    end

    module Redis
      Base = ::Treasury::Storage::Redis::Base
      Multi = ::Treasury::Storage::Redis::Multi
    end
  end

  ROOT_REDIS_KEY = ::Treasury::ROOT_REDIS_KEY
end

Pgq = ::Treasury::Pgq
