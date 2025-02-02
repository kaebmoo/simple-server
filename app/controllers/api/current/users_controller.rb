class Api::Current::UsersController < APIController
  skip_before_action :current_user_present?, only: [:register, :find, :request_otp]
  skip_before_action :validate_sync_approval_status_allowed, only: [:register, :find, :request_otp]
  skip_before_action :authenticate, only: [:register, :find, :request_otp]
  skip_before_action :validate_facility, only: [:register, :find, :request_otp]
  skip_before_action :validate_current_facility_belongs_to_users_facility_group, only: [:register, :find, :request_otp]
  before_action :validate_registration_payload, only: %i[register]

  def register
    user = User.build_with_phone_number_authentication(user_from_request)
    return head :not_found unless user.registration_facility.present?

    if user.phone_number_authentication.invalid?
      return render json: {
        errors: user.phone_number_authentication.errors
      }, status: :bad_request
    end

    send_approval_email(user) if approve_and_save(user)

    render json: {
      user: user_to_response(user),
      access_token: user.access_token
    }, status: :ok
  end

  def find
    return head :bad_request unless find_params.present?
    user = find_user(find_params)
    return head :not_found unless user.present?
    render json: user_to_response(user), status: 200
  end

  def request_otp
    user = User.find(request_user_id)
    phone_number_authentication = user.phone_number_authentication
    phone_number_authentication.set_otp
    phone_number_authentication.save

    SmsNotificationService
      .new(user.phone_number, ENV['TWILIO_PHONE_NUMBER'])
      .send_request_otp_sms(user.otp) unless FeatureToggle.auto_approve_for_qa?

    head :ok
  end

  def reset_password
    current_user.reset_phone_number_authentication_password!(reset_password_digest)

    unless FeatureToggle.auto_approve_for_qa?
      ApprovalNotifierMailer
        .delay
        .reset_password_approval_email(user_id: current_user.id)
    end

    render json: {
      user: user_to_response(current_user),
      access_token: current_user.access_token
    }, status: :ok
  end

  private

  def approve_and_save(user)
    FeatureToggle.auto_approve_for_qa? ?
      user.sync_approval_allowed :
      user.sync_approval_requested(I18n.t('registration'))

    user.save
  end

  def send_approval_email(user)
    return if FeatureToggle.auto_approve_for_qa?

    ApprovalNotifierMailer
      .delay
      .registration_approval_email(user_id: user.id)
  end

  def find_user(params)
    if params[:id].present?
      User.find_by(id: find_params[:id])
    elsif params[:phone_number].present?
      phone_number_authentication = PhoneNumberAuthentication.find_by(phone_number: params[:phone_number])
      phone_number_authentication.user if phone_number_authentication.present?
    end
  end

  def user_from_request
    Api::Current::Transformer.from_request(registration_params)
  end

  def user_to_response(user)
    Api::Current::UserTransformer.to_response(user)
  end

  def validate_registration_payload
    validator = Api::Current::UserRegistrationPayloadValidator.new(registration_params)
    logger.debug "User registration params had errors: #{validator.errors_hash}" if validator.invalid?
    if validator.invalid?
      render json: { errors: validator.errors }, status: :bad_request
    end
  end

  def registration_params
    params.require(:user)
      .permit(
        :id,
        :full_name,
        :phone_number,
        :password_digest,
        :updated_at,
        :created_at,
        :registration_facility_id)
  end

  def find_params
    params.permit(:id, :phone_number)
  end

  def request_user_id
    params.require(:id)
  end

  def reset_password_digest
    params.require(:password_digest)
  end
end
