require 'spec_helper'
require 'shared-examples'
manifest = 'master/nginx_repo.pp'

# HIERA: master
# FACTS: master_centos7 master_centos6

describe manifest do
  shared_examples 'catalog' do
    let(:service_enabled) do
      !! (facts[:operatingsystemrelease] =~ /^7.*/)
    end

    it { is_expected.to contain_class('fuel::nginx::repo').with(:service_enabled => service_enabled) }
  end

  run_test manifest
end
