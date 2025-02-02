METHODS_TO_INSTRUMENT = [
  [Api::Current::PatientTransformer.singleton_class, :from_nested_request],
  [Api::Current::PatientTransformer.singleton_class, :to_nested_response],

  [Api::Current::BloodPressureTransformer.singleton_class, :from_request],
  [Api::Current::BloodPressureTransformer.singleton_class, :to_response],

  [Api::Current::PatientsController, :current_facility_records],
  [Api::Current::PatientsController, :other_facility_records],

  [Api::Current::PatientsController, :merge_if_valid],
  [Api::Current::BloodPressuresController, :merge_if_valid],
  [Api::Current::AppointmentsController, :merge_if_valid],
  [Api::Current::PrescriptionDrugsController, :merge_if_valid],
  [Api::Current::MedicalHistoriesController, :merge_if_valid],

  [Api::Current::BloodPressuresController, :current_facility_records],
  [Api::Current::BloodPressuresController, :other_facility_records],

  [Api::Current::BloodPressurePayloadValidator, :invalid?],
  [Api::Current::AppointmentPayloadValidator, :invalid?],
  [Api::Current::PrescriptionDrugPayloadValidator, :invalid?],

  [MergePatientService, :merge],
  [BloodPressure.singleton_class, :merge],
  [Appointment.singleton_class, :merge],
  [PrescriptionDrug.singleton_class, :merge]
]

METHODS_TO_INSTRUMENT.each do |class_method|
  cls = class_method[0]
  method = class_method[1]

  cls.class_eval do
    include ::NewRelic::Agent::MethodTracer
    add_method_tracer method
  end
end