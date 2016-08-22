require 'spec_helper'

describe 'cluster::galera_status' do

  shared_examples_for 'galera_status configuration' do

  end

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge(common_facts).merge(
            {
                :openstack_version => {'nova' => 'present'}
            }
        )
      end
      it_configures 'galera_status configuration'
    end
  end

end
