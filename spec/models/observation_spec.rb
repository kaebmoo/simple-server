require 'rails_helper'

RSpec.describe Observation, type: :model do
  describe 'Associations' do
    it { should belong_to(:encounter) }
    it { should belong_to(:user) }
    it { should belong_to(:observable) }
  end
end
