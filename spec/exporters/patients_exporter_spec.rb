require "rails_helper"

RSpec.describe PatientsExporter do
  include QuarterHelper

  let!(:facility) { create(:facility) }
  let!(:patient) { create(:patient, registration_facility: facility) }
  let!(:blood_pressure) { create(:blood_pressure, facility: facility, patient: patient) }
  let!(:appointment) { create(:appointment, :overdue, facility: facility, patient: patient) }

  let(:headers) do
    [
      "Simple Patient ID",
      "BP Passport ID",
      "Patient Name",
      "Patient Gender",
      "Patient Age",
      "Patient Village/Colony",
      "Patient District",
      "Patient State",
      "Patient Phone Number",
      "Registration Date",
      "Registration Quarter",
      "Registration Facility Name",
      "Registration Facility Type",
      "Registration Facility District",
      "Registration Facility State",
      "Latest BP Systolic",
      "Latest BP Diastolic",
      "Latest BP Date",
      "Latest BP Quarter",
      "Latest BP Facility Name",
      "Latest BP Facility Type",
      "Latest BP Facility District",
      "Latest BP Facility State",
      "Days Overdue",
      "Risk Level"
    ]
  end

  let(:fields) do
    [
      patient.id,
      patient.latest_bp_passport&.shortcode,
      patient.full_name,
      patient.gender.capitalize,
      patient.current_age,
      patient.address.village_or_colony,
      patient.address.district,
      patient.address.state,
      patient.phone_numbers.last&.number,
      I18n.l(patient.recorded_at),
      quarter_string(patient.recorded_at),
      facility.name,
      facility.facility_type,
      facility.district,
      facility.state,
      blood_pressure.systolic,
      blood_pressure.diastolic,
      I18n.l(blood_pressure.recorded_at),
      quarter_string(blood_pressure.recorded_at),
      blood_pressure.facility.name,
      blood_pressure.facility.facility_type,
      blood_pressure.facility.district,
      blood_pressure.facility.state,
      appointment.days_overdue,
      patient.risk_priority_label
    ]
  end

  describe "#csv" do
    it "generates a CSV of patient records" do
      expect(subject.csv(Patient.all)).to eq(headers.to_csv + fields.to_csv)
    end

    it "generates a blank CSV (only headers) if no patients exist" do
      expect(subject.csv(Patient.none)).to eq(headers.to_csv)
    end

    it "uses fetches patients in batches" do
      expect_any_instance_of(facility.registered_patients.class)
        .to receive(:in_batches).and_return([[patient]])

      subject.csv(facility.registered_patients)
    end
  end
end

