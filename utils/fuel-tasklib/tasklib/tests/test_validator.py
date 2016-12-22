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

import copy
import jsonschema
import mock

from unittest2 import case

from tasklib import validator


TASKS = [
    {'id': 'pre_deployment_start',
     'type': 'stage'},
    {'id': 'pre_deployment_end',
     'requires': ['pre_deployment_start'],
     'type': 'stage'},
    {'id': 'deploy_start',
     'requires': ['pre_deployment_end'],
     'type': 'stage'},
    {'id': 'deploy_end',
     'requires': ['deploy_start'],
     'type': 'stage'},
    {'id': 'post_deployment_start',
     'requires': ['deploy_end'],
     'type': 'stage'},
    {'id': 'post_deployment_end',
     'requires': ['post_deployment_start'],
     'type': 'stage'}]


class TestValidator61(case.TestCase):

    def setUp(self):
        self.tasks = copy.deepcopy(TASKS)

    def test_validate_schema(self):
        valid_tasks = validator.TasksValidator(self.tasks, "6.1")
        valid_tasks.validate_schema()

    def test_wrong_schema(self):
        self.tasks.append({'id': 'wrong',
                           'type': 'non existing'})
        valid_tasks = validator.TasksValidator(self.tasks, "6.1")
        self.assertRaises(jsonschema.ValidationError,
                          valid_tasks.validate_schema)

    def test_empty_id_schema(self):
        self.tasks.append({'id': '',
                           'type': 'stage'})
        valid_tasks = validator.TasksValidator(self.tasks, "6.1")
        self.assertRaises(jsonschema.ValidationError,
                          valid_tasks.validate_schema)

    def test_validate_graph(self):
        valid_tasks = validator.TasksValidator(self.tasks, "6.1")
        valid_tasks.validate_graph()

    def test_validate_cyclic_graph(self):
        self.tasks.append({'id': 'post_deployment_part',
                           'type': 'stage',
                           'requires': ['post_deployment_start'],
                           'required_for': ['pre_deployment_start']})
        valid_tasks = validator.TasksValidator(self.tasks, "6.1")
        self.assertRaises(ValueError,
                          valid_tasks.validate_graph)

    def test_validate_not_connected_graph(self):
        self.tasks.append({'id': 'post_deployment_part',
                           'type': 'stage'})
        valid_tasks = validator.TasksValidator(self.tasks, "6.1")
        self.assertRaises(ValueError,
                          valid_tasks.validate_graph)

    def test_validate_duplicated_tasks(self):
        self.tasks.append({'id': 'pre_deployment_start',
                           'type': 'stage'})
        valid_tasks = validator.TasksValidator(self.tasks, "6.1")
        self.assertRaises(ValueError,
                          valid_tasks.validate_unique_tasks)

    def test_validate_empty_nodes(self):
        self.tasks.append({'id': 'some_task',
                           'type': 'stage',
                           'requires': ['empty_node',
                                        'post_deployment_start']})
        valid_tasks = validator.TasksValidator(self.tasks, "6.1")
        self.assertRaises(ValueError,
                          valid_tasks.validate_graph)


class TestValidatorClient(case.TestCase):

    def test_no_dir(self):
        args = ['script/name']
        try:
            validator.main(args)
        except SystemExit as pars_error:
            pass
        self.assertEqual(pars_error[0], 2)

    @mock.patch('tasklib.validator.get_tasks')
    @mock.patch('tasklib.validator.TasksValidator')
    def test_passing_params(self, mock_validator, mock_file):
        mock_file.return_value = TASKS
        args = ['/usr/local/bin/tasks-validator', '-d',
                './path', '-v', '6.1']
        validator.main(args)
        mock_file.called_with('./path')
        mock_validator.assert_called_with(TASKS, '6.1')
