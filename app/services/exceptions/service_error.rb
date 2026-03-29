module Exceptions
  class ServiceError < StandardError
    attr_reader :data, :errors

    def initialize(message = nil, success: false, data: nil, errors: nil)
      super(message)

      @success = success
      @data = data
      @errors = errors || message
    end

    def success?
      @success
    end
  end
end