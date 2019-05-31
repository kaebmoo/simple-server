class UserPermission < ApplicationRecord
  belongs_to :user, class_name: 'MasterUser'
  belongs_to :resource, polymorphic: true, optional: true

  validates :permission_slug, presence: true
end