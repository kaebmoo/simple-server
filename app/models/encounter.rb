class Encounter < ApplicationRecord
  include Mergeable

  belongs_to :patient, optional: true
  belongs_to :facility

  has_many :observations
  has_many :blood_pressures, through: :observations, source: :observable, source_type: 'BloodPressure'

  def self.generate_id(facility_id, patient_id, encountered_on)
    UUIDTools::UUID
      .sha1_create(UUIDTools::UUID_DNS_NAMESPACE,
                   [facility_id, patient_id, encountered_on].join(""))
      .to_s
  end

  def self.generate_encountered_on(time, timezone_offset)
    time
      .to_time
      .utc
      .advance(seconds: timezone_offset)
      .to_date
  end
end
