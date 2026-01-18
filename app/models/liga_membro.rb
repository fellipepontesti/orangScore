class LigaMembro < ApplicationRecord
  belongs_to :liga
  belongs_to :user

  enum :role, { owner: 0, admin: 1, member: 2 }
  enum :status, { invited: 0, accepted: 1, pending_deletion: 2 }
end
