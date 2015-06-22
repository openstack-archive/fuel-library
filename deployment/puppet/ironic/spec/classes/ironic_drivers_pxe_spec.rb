#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for ironic::drivers::pxe class
#

require 'spec_helper'

describe 'ironic::drivers::pxe' do

  let :default_params do
    { :pxe_append_params    => 'nofb nomodeset vga=normal',
      :pxe_config_template  => '$pybasedir/drivers/modules/pxe_config.template',
      :pxe_deploy_timeout   => '0',
      :tftp_server          => '$my_ip',
      :tftp_root            => '/tftpboot',
      :images_path          => '/var/lib/ironic/images/',
      :tftp_master_path     => '/tftpboot/master_images',
      :instance_master_path => '/var/lib/ironic/master_images' }
  end

  let :params do
    {}
  end

  shared_examples_for 'ironic pxe driver' do
    let :p do
      default_params.merge(params)
    end

    it 'configures ironic.conf' do
      is_expected.to contain_ironic_config('pxe/pxe_append_params').with_value(p[:pxe_append_params])
      is_expected.to contain_ironic_config('pxe/pxe_config_template').with_value(p[:pxe_config_template])
      is_expected.to contain_ironic_config('pxe/pxe_deploy_timeout').with_value(p[:pxe_deploy_timeout])
      is_expected.to contain_ironic_config('pxe/tftp_server').with_value(p[:tftp_server])
      is_expected.to contain_ironic_config('pxe/tftp_root').with_value(p[:tftp_root])
      is_expected.to contain_ironic_config('pxe/images_path').with_value(p[:images_path])
      is_expected.to contain_ironic_config('pxe/tftp_master_path').with_value(p[:tftp_master_path])
      is_expected.to contain_ironic_config('pxe/instance_master_path').with_value(p[:instance_master_path])
    end

    context 'when overriding parameters' do
      before do
        params.merge!(
          :deploy_kernel        => 'foo',
          :deploy_ramdisk       => 'bar',
          :pxe_append_params    => 'foo',
          :pxe_config_template  => 'bar',
          :pxe_deploy_timeout   => '40',
          :tftp_server          => '192.168.0.1',
          :tftp_root            => '/mnt/ftp',
          :images_path          => '/mnt/images',
          :tftp_master_path     => '/mnt/master_images',
          :instance_master_path => '/mnt/ironic/master_images'
        )
      end

      it 'should replace default parameter with new value' do
        is_expected.to contain_ironic_config('pxe/deploy_kernel').with_value(p[:deploy_kernel])
        is_expected.to contain_ironic_config('pxe/deploy_ramdisk').with_value(p[:deploy_ramdisk])
        is_expected.to contain_ironic_config('pxe/pxe_append_params').with_value(p[:pxe_append_params])
        is_expected.to contain_ironic_config('pxe/pxe_config_template').with_value(p[:pxe_config_template])
        is_expected.to contain_ironic_config('pxe/pxe_deploy_timeout').with_value(p[:pxe_deploy_timeout])
        is_expected.to contain_ironic_config('pxe/tftp_server').with_value(p[:tftp_server])
        is_expected.to contain_ironic_config('pxe/tftp_root').with_value(p[:tftp_root])
        is_expected.to contain_ironic_config('pxe/images_path').with_value(p[:images_path])
        is_expected.to contain_ironic_config('pxe/tftp_master_path').with_value(p[:tftp_master_path])
        is_expected.to contain_ironic_config('pxe/instance_master_path').with_value(p[:instance_master_path])
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    it_configures 'ironic pxe driver'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'ironic pxe driver'
  end

end
