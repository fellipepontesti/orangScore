module Ligas
  class Destroy
    def initialize(liga:)
      @liga = liga
    end

    def call
      @liga.destroy!
    end
  end
end
