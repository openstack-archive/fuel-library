#    Copyright 2014 Mirantis, Inc.
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

import os
from fnmatch import fnmatch
import logging

import pytest
import yaml

from tasks_validator import validator

logging.basicConfig(level=logging.DEBUG)

log = logging.getLogger(__name__)


def get_files(base_dir, file_pattern='*tasks.yaml'):
    for root, _dirs, files in os.walk(base_dir):
        for file_name in files:
            if fnmatch(file_name, file_pattern):
                yield os.path.join(root, file_name)


@pytest.fixture(scope='module')
def tasks(request):
    tasks = []
    for file_path in get_files(request.config.getoption('dir')):
        log.info('Reading tasks from file %s', file_path)
        with open(file_path) as f:
            tasks.extend(yaml.load(f.read()))
    return tasks


def test_tasks_schema(tasks):
    t_validator = validator.TasksValidator(tasks, 'newest')
    t_validator.validate_schema()


def test_tasks_graph(tasks):
    t_validator = validator.TasksValidator(tasks, 'newest')
    t_validator.validate_graph()
