module Ligas
  class Update
    def initialize(liga:, params:)
      @liga = liga
      @params = params
    end

    def call
      @liga.update(@params)
      @liga
    end
  end
end
