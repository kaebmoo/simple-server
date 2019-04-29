class PhoneNumberAuthentication < ApplicationRecord
  has_secure_password

  has_many :master_user_authentication, as: :authenticatable

  validates :phone_number, presence: true, uniqueness: true, case_sensitive: false
  validates :password, allow_blank: true, length: { is: 4 }, format: { with: /[0-9]/, message: 'only allows numbers' }
  validate :presence_of_password

  def presence_of_password
    unless password_digest.present? || password.present?
      errors.add(:password, 'Either password_digest or password should be present')
    end
  end
end