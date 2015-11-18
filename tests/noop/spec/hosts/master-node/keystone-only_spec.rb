require 'spec_helper'
require 'shared-examples'
manifest = '../../nailgun/examples/keystone-only.pp'

describe manifest do
  shared_examples 'catalog' do

    let(:facts) {
      Noop.centos_facts.merge(Noop.hiera('facts'))
      Noop.ubuntu_facts.merge(Noop.hiera('facts'))
    }

  end

  test_ubuntu_and_centos(manifest, true)
end

