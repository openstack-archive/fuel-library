#    Copyright 2015 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

from mock import Mock
import vcenter_hooks


def test_check_new_az():
    "check that vcenter_hooks.check_availability_zones try to create new az"
    nova_client = Mock()
    v = Mock()
    v.to_dict.return_value = {'availability_zone': 'vcenter1'}
    nova_client.availability_zones.list.return_value = [v]
    nova_client.aggregates.list.return_value = []
    compute = {'availability_zone_name': 'vcenter'}
    vcenter_hooks.check_availability_zones(nova_client, compute)
    nova_client.aggregates.create.assert_called_once_with(
        compute['availability_zone_name'], compute['availability_zone_name'])


def test_check_not_new_az():
    "check that vcenter_hooks.check_availability_zones doesn't try to create\
    existing avialability_zones"
    nova_client = Mock()
    v = Mock()
    v.to_dict.return_value = {'availability_zone': 'vcenter'}
    nova_client.availability_zones.list.return_value = [v]
    nova_client.aggregates.list.return_value = []
    compute = {'availability_zone_name': 'vcenter'}
    vcenter_hooks.check_availability_zones(nova_client, compute)
    assert not nova_client.aggregates.create.called, \
        'Fail. Trying to create existing availability zone'


def test_check_host_not_in_zone():
    "check that vcenter_hooks.check_host_in_zone add host to zone"
    nova_client = Mock()
    h = Mock()
    h.to_dict.return_value = {'hosts': 'vcenter-compute',
                              'zoneName': 'vcenters'}
    nova_client.availability_zones.list.return_value = [h]
    a = Mock()
    a.to_dict.return_value = {'name': 'vcenter'}
    nova_client.aggregates.list.return_value = [a]
    compute = {'availability_zone_name': 'vcenter',
               'service_name': 'compute'}
    vcenter_hooks.check_host_in_zone(nova_client, compute)
    nova_client.aggregates.add_host.assert_called_once_with(a,
                                                            'vcenter-compute')


def test_check_host_in_zone():
    "check that vcenter_hooks.check_host_in_zone doesn't add host to zone\
    when it already here"
    nova_client = Mock()
    h = Mock()
    h.to_dict.return_value = {'hosts': 'vcenter-compute',
                              'zoneName': 'vcenter'}
    nova_client.availability_zones.list.return_value = [h]
    nova_client.aggregates.list.return_value = ['']
    compute = {'availability_zone_name': 'vcenter',
               'service_name': 'compute'}
    vcenter_hooks.check_host_in_zone(nova_client, compute)
    assert not nova_client.aggregates.add_host.called,\
        'Fail. Trying to add host to aggregation which already here.'
