class UserPoint < ApplicationRecord
  belongs_to :user
  belongs_to :jogo
end
