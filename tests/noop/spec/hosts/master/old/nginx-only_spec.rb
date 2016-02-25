require 'spec_helper'
require 'shared-examples'
manifest = 'master/nginx-only.pp'

describe manifest do
  shared_examples 'catalog' do
    let(:facts) do
      Noop.centos_facts.merge({
        :interfaces => 'eth0,eth1'
      })
    end
  end
  test_centos manifest
end
