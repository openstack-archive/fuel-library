require 'spec_helper'

describe 'uuid_dmi fact' do
  subject(:fact) { Facter.fact(:uuid_dmi) }

  before :each do
    Facter::Util::Resolution.stubs(:exec).with(
      'dmidecode 2>/dev/null | grep UUID').returns(
      'UUID: 4C4C4544-005A-5310-8046-B3C04F423632')
    Facter::Util::Resolution.stubs(:exec).with(
      'uuidgen').returns(
      '2e3c85d0-2563-4cfc-a83b-4dd9a994afb9')
  end

  it 'should return valid UUID' do
    Facter.fact(:uuid_dmi).value.should ==
      '4c4c4544-005a-5310-8046-b3c04f423632'
  end

  it 'should fallback to the uuidgen' do
    Facter::Util::Resolution.stubs(:exec).with(
      'dmidecode 2>/dev/null | grep UUID').returns(
      'nothing good')
    Facter.fact(:uuid_dmi).value.should ==
      '2e3c85d0-2563-4cfc-a83b-4dd9a994afb9'
  end

  after :each do
    Facter.clear
    Facter.clear_messages
  end
end
