class User < ApplicationRecord

  self.table_name = 'master_users'

  AUTHENTICATION_TYPES = {
    email_authentication: 'EmailAuthentication',
    phone_number_authentication: 'PhoneNumberAuthentication'
  }

  enum sync_approval_status: {
    requested: 'requested',
    allowed: 'allowed',
    denied: 'denied'
  }, _prefix: true

  has_many :user_authentications
  has_many :blood_pressures
  has_many :patients, -> { distinct }, through: :blood_pressures
  has_many :phone_number_authentications, through: :user_authentications, source: :authenticatable, source_type: 'PhoneNumberAuthentication'
  has_many :audit_logs, as: :auditable
  has_many :appointments
  has_many :medical_histories
  has_many :prescription_drugs

  has_many :registered_patients, class_name: "Patient", foreign_key: 'registration_user_id'

  validates :full_name, presence: true

  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  delegate :registration_facility,
           :access_token,
           :logged_in_at,
           :has_never_logged_in?,
           :mark_as_logged_in,
           :phone_number,
           :otp,
           :otp_valid?,
           :facility_group,
           :organization,
           :password_digest, to: :phone_number_authentication, allow_nil: true

  def phone_number_authentication
    phone_number_authentications.first
  end

  def registration_facility_id
    registration_facility.id
  end

  alias_method :facility, :registration_facility

  def access_token_valid?
    self.sync_approval_status_allowed?
  end

  def self.build_with_phone_number_authentication(params)
    phone_number_authentication = PhoneNumberAuthentication.new(
      phone_number: params[:phone_number],
      password_digest: params[:password_digest],
      registration_facility_id: params[:registration_facility_id]
    )
    phone_number_authentication.set_otp
    phone_number_authentication.set_access_token

    user = new(
      id: params[:id],
      full_name: params[:full_name],
      device_created_at: params[:device_created_at],
      device_updated_at: params[:device_updated_at]
    )
    user.sync_approval_requested(I18n.t('registration'))

    user.phone_number_authentications = [phone_number_authentication]
    user
  end

  def update_with_phone_number_authentication(params)
    user_params = params.slice(:full_name, :sync_approval_status, :sync_approval_status_reason)
    phone_number_authentication_params = params.slice(
      :phone_number,
      :password,
      :password_digest,
      :registration_facility_id
    )

    transaction do
      update!(user_params) && phone_number_authentication.update!(phone_number_authentication_params)
    end
  end

  def sync_approval_denied(reason = "")
    self.sync_approval_status = :denied
    self.sync_approval_status_reason = reason
  end

  def sync_approval_allowed(reason = "")
    self.sync_approval_status = :allowed
    self.sync_approval_status_reason = reason
  end

  def sync_approval_requested(reason)
    self.sync_approval_status = :requested
    self.sync_approval_status_reason = reason
  end

  def reset_phone_number_authentication_password!(password_digest)
    transaction do
      authentication = phone_number_authentication
      authentication.password_digest = password_digest
      authentication.set_access_token
      self.sync_approval_requested(I18n.t('reset_password'))
      authentication.save!
      self.save!
    end
  end

  def self.requested_sync_approval
    where(sync_approval_status: :requested)
  end
end
