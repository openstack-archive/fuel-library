# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'murano/upload_murano_package.pp'

describe manifest do
  shared_examples 'catalog' do

    enable = (Noop.hiera_structure('murano/enabled') and Noop.hiera('role') == 'primary-controller')

    context 'on primary controller', :if => enable do
      it 'should declare murano::application resource correctly' do
        should contain_murano__application('io.murano')
      end
    end
  end # end of shared_examples

  test_ubuntu_and_centos manifest
end
