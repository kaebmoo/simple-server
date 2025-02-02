class MedicalHistory < ApplicationRecord
  include Mergeable
  belongs_to :patient, optional: true
  belongs_to :user, optional: true


  validates :device_created_at, presence: true
  validates :device_updated_at, presence: true

  MEDICAL_HISTORY_QUESTIONS = [
    :prior_heart_attack,
    :prior_stroke,
    :chronic_kidney_disease,
    :receiving_treatment_for_hypertension,
    :diabetes,
    :diagnosed_with_hypertension
  ].freeze

  MEDICAL_HISTORY_ANSWERS = {
    yes: 'yes',
    no: 'no',
    unknown: 'unknown'
  }.freeze

  enum prior_heart_attack: MEDICAL_HISTORY_ANSWERS, _prefix: true
  enum prior_stroke: MEDICAL_HISTORY_ANSWERS, _prefix: true
  enum chronic_kidney_disease: MEDICAL_HISTORY_ANSWERS, _prefix: true
  enum receiving_treatment_for_hypertension: MEDICAL_HISTORY_ANSWERS, _prefix: true
  enum diabetes: MEDICAL_HISTORY_ANSWERS, _prefix: true
  enum diagnosed_with_hypertension: MEDICAL_HISTORY_ANSWERS, _prefix: true

  def indicates_risk?
    prior_heart_attack_boolean ||
      prior_stroke_boolean ||
      diabetes_boolean ||
      chronic_kidney_disease_boolean
  end
end
