require 'spec_helper'
require 'shared-examples'
manifest = 'master/puppetsync.pp'

# HIERA: master
# FACTS: master_centos7

describe manifest do
  shared_examples 'catalog' do
    it { is_expected.to contain_class 'fuel::puppetsync' }

    it 'should contain "rsyncd" fuel::systemd service with parameters' do
      parameters = {
          :start => true,
          :template_path => 'fuel/systemd/restart_template.erb',
          :config_name => 'restart.conf',
      }
      is_expected.to contain_fuel__systemd('rsyncd').with parameters
    end
  end
  run_test manifest
end
