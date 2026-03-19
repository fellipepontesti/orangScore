module Exceptions
  class ServiceError
    attr_reader :data, :errors

    def initialize(success:, data: nil, errors: nil)
      @success = success
      @data = data
      @errors = errors
    end

    def success?
      @success
    end
  end
end
