require 'swagger_helper'

describe 'Encounters Current API', swagger_doc: 'current/swagger.json' do
  path '/encounters/sync' do

    post 'Syncs encounters data from device to server.' do
      tags 'Encounters'
      security [basic: []]
      parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
      parameter name: 'HTTP_X_FACILITY_ID', in: :header, type: :uuid
      parameter name: :encounters, in: :body, schema: Api::Current::Schema.encounter_sync_from_user_request

      response '200', 'encounters created' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        let(:encounters) { { encounters: (1..3).map { build_encounters_payload } } }

        run_test!
      end

      response '200', 'some, or no errors were found' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::Current::Schema.sync_from_user_errors
        let(:encounters) { { encounters: (1..3).map { build_invalid_encounters_payload } } }
        run_test!
      end

      include_examples 'returns 403 for post requests for forbidden users', :encounters
    end

    get 'Syncs encounters data from server to device.' do
      tags 'Encounters'
      security [basic: []]
      parameter name: 'HTTP_X_USER_ID', in: :header, type: :uuid
      parameter name: 'HTTP_X_FACILITY_ID', in: :header, type: :uuid
      Api::Current::Schema.sync_to_user_request.each do |param|
        parameter param
      end

      before :each do
        Timecop.travel(10.minutes.ago) do
          FactoryBot.create_list(:encounter, 3)
        end
      end

      response '200', 'encounters received' do
        let(:request_user) { FactoryBot.create(:user) }
        let(:request_facility) { FactoryBot.create(:facility, facility_group: request_user.facility.facility_group) }
        let(:HTTP_X_USER_ID) { request_user.id }
        let(:HTTP_X_FACILITY_ID) { request_facility.id }
        let(:Authorization) { "Bearer #{request_user.access_token}" }

        schema Api::Current::Schema.encounter_sync_to_user_response
        let(:process_token) { Base64.encode64({ other_facilities_processed_since: 10.minutes.ago }.to_json) }
        let(:limit) { 10 }
        run_test!
      end

      include_examples 'returns 403 for get requests for forbidden users'
    end
  end
end
