module HasPublicUuid
  extend ActiveSupport::Concern

  included do
    before_validation :ensure_uuid, on: :create

    validates :uuid, presence: true, uniqueness: true
  end

  class_methods do
    def find_by_uuid_param!(param)
      find_by!(uuid: param)
    end
  end

  def to_param
    uuid
  end

  private

  def ensure_uuid
    self.uuid ||= SecureRandom.uuid
  end
end
