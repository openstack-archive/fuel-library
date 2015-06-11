#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
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

require 'spec_helper'

describe 'openstacklib::messaging::rabbitmq' do

  let (:title) { 'nova' }

  shared_examples 'openstacklib::messaging::rabbitmq examples' do

    let :params do
      {}
    end

    context 'with default parameters' do
      it { should contain_rabbitmq_user('guest').with(
        :admin    => false,
        :password => 'guest',
        :provider => 'rabbitmqctl',
      )}
      it { should contain_rabbitmq_user_permissions('guest@/').with(
        :configure_permission => '.*',
        :write_permission     => '.*',
        :read_permission      => '.*',
        :provider             => 'rabbitmqctl',
      )}
      it { should contain_rabbitmq_vhost('/').with(
        :provider => 'rabbitmqctl',
      )}
    end

    context 'with custom parameters' do
      before :each do
        params.merge!(
          :userid               => 'nova',
          :password             => 'secrete',
          :virtual_host         => '/nova',
          :is_admin             => true,
          :configure_permission => '.nova',
          :write_permission     => '.nova',
          :read_permission      => '.nova'
        )
      end

      it { should contain_rabbitmq_user('nova').with(
        :admin    => true,
        :password => 'secrete',
        :provider => 'rabbitmqctl',
      )}
      it { should contain_rabbitmq_user_permissions('nova@/nova').with(
        :configure_permission => '.nova',
        :write_permission     => '.nova',
        :read_permission      => '.nova',
        :provider             => 'rabbitmqctl',
      )}
      it { should contain_rabbitmq_vhost('/nova').with(
        :provider => 'rabbitmqctl',
      )}
    end

    context 'when disabling vhost management' do
      before :each do
        params.merge!( :manage_vhost => false )
      end

      it { should_not contain_rabbitmq_vhost }
    end

  end

  context 'on a Debian osfamily' do
    let :facts do
      { :osfamily => "Debian" }
    end

    include_examples 'openstacklib::messaging::rabbitmq examples'
  end

  context 'on a RedHat osfamily' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    include_examples 'openstacklib::messaging::rabbitmq examples'
  end
end
