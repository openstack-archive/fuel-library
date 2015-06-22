require 'spec_helper'

describe 'test-001.example.org' do

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    # Bug #1278452
    it 'nova::consoleauth and nova::spicehtml5proxy do not conflict' do
      is_expected.to contain_class('nova::consoleauth')
      is_expected.to contain_class('nova::spicehtml5proxy')

      is_expected.to contain_nova__generic_service('consoleauth')
      is_expected.to contain_nova__generic_service('spicehtml5proxy')
    end
  end
end
