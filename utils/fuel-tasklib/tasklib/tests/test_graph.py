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

from unittest2 import case

from tasklib import graph


class TestGraphs(case.TestCase):

    def test_connectability(self):
        tasks = [
            {'id': 'pre_deployment_start',
             'type': 'stage'},
            {'id': 'pre_deployment_end',
             'type': 'stage',
             'requires': ['pre_deployment_start']},
            {'id': 'deploy_start',
             'type': 'stage'}]
        tasks_graph = graph.DeploymentGraph(tasks)
        self.assertFalse(tasks_graph.is_connected())

    def test_cyclic(self):
        tasks = [
            {'id': 'pre_deployment_start',
             'type': 'stage'},
            {'id': 'pre_deployment_end',
             'type': 'stage',
             'requires': ['pre_deployment_start']},
            {'id': 'deploy_start',
             'type': 'stage',
             'requires': ['pre_deployment_end'],
             'required_for': ['pre_deployment_start']}]
        tasks_graph = graph.DeploymentGraph(tasks)
        cycles = tasks_graph.find_cycles()
        self.assertEqual(len(cycles), 1)
        self.assertItemsEqual(cycles[0], ['deploy_start',
                                          'pre_deployment_start',
                                          'pre_deployment_end'])

    def test_empty_nodes(self):
        tasks = [
            {'id': 'pre_deployment_start',
             'type': 'stage',
             'requires': ['empty_node']},
            {'id': 'pre_deployment_end',
             'type': 'stage',
             'requires': ['pre_deployment_start']},
            {'id': 'deploy_start',
             'type': 'stage',
             'requires': ['empty_node_2']}]
        tasks_graph = graph.DeploymentGraph(tasks)
        self.assertItemsEqual(tasks_graph.find_empty_nodes(), ['empty_node',
                                                               'empty_node_2'])
