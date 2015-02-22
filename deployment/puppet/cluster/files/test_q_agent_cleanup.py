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
from mock import mock_open
from mock import patch
import pytest

# Yes, q-agent-cleanup has dashes, this is necessary to bypass the import
# restriction. It's normally not a module, we only need this for testing.
qagent = __import__('q-agent-cleanup')


qagent.RETRY_DELAY = RETRY_DELAY = 0
qagent.RETRY_COUNT = RETRY_COUNT = 10


def build_mock(effect):
    mock = Mock()
    mock.side_effect = effect
    # http://stackoverflow.com/questions/22204660/python-mock-wrapsf-problems
    mock.__name__ = 'foo'
    return mock


def test_retry_NotEpectedError():
    mock = build_mock(TypeError)
    pytest.raises(TypeError, qagent.retry(mock))
    mock.assert_called_once_with()


def test_retry_RecoverableError():
    mock = build_mock([Exception('503 Service Unavailable')] * 5 + [True])
    ret = qagent.retry(mock)()
    assert ret
    assert mock.call_count == 6


def test_retry_RecoveryTimedOut():
    mock = build_mock(Exception('503 Service Unavailable'))
    pytest.raises(Exception, qagent.retry(mock))
    assert mock.call_count == RETRY_COUNT


def test_retry_CallSuccess():
    mock = build_mock([True])
    qagent.retry(mock)()
    mock.assert_called_once_with()


def test_get_authdata():
    cfg = """[keystone_authtoken]
admin_tenant_name = tenant
admin_user = admin
admin_password = password
auth_uri = http://127.0.0.1:5000/v2.0/

    """
    actual = {
    'tenant_name': 'tenant',
    'username': 'admin',
    'password': 'password',
    'auth_url': 'http://127.0.0.1:5000/v2.0/',
    }

    mock = mock_open()
    mock.return_value.readline = Mock()
    mock.return_value.readline.side_effect = cfg.split('\n')

    with patch("__builtin__.open", mock):
        read_data = qagent.get_auth_data('file')
    assert read_data == actual
