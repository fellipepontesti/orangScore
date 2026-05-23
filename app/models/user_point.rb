class UserPoint < ApplicationRecord
  include HasPublicUuid
  belongs_to :user
  belongs_to :jogo
end
