require 'spec_helper'
require 'shared-examples'
manifest = 'ntp/ntp-client.pp'

describe manifest do

  shared_examples 'catalog' do
    let(:role) do
      Noop.hiera 'role'
    end

    let(:management_vip) do
      Noop.hiera 'management_vrouter_vip'
    end

    let(:is_controller?) do
      %w(controller primary-controller).include? role
    end

    it 'does not try to setup the ntp server on a controller or a primary controller' do
      expect(subject).not_to contain_class('Ntp') if is_controller?
    end

    it 'setups the ntp service on the non-controller nodes' do
      expect(subject).to contain_class('Ntp') unless is_controller?
    end

    it "ntp service should sync time from the management_vip" do
      next true if is_controller?

      should contain_class('ntp').with(
        'servers' => management_vip,
      )
    end
  end

  test_ubuntu_and_centos manifest
end

