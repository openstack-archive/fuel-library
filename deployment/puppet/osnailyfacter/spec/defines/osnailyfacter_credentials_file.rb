require 'spec_helper'

describe 'osnailyfacter::credentials_file' do

  context 'with defaults' do
    let (:title) { '/root/openrc' }

    it 'should include openrc file' do
      is_expected.to contain_file('/root/openrc')
    end
  end

  context 'with non-root user' do
    let (:title) { '/home/fueladmin/openrc' }
    let :params do
      :owner => 'fueladmin',
      :group => 'fueladmin',
    end

    it 'should include openrc file for a non-root user with correct permissions' do
      is_expected.to contain_file('/home/fueladmin/openrc').with(
        'owner' => 'fueladmin',
        'group' => 'fueladmin'
      )
    end
  end

end

