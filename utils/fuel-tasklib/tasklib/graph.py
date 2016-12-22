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

import networkx as nx


class DeploymentGraph(object):

    def __init__(self, tasks):
        self.tasks = tasks
        self.graph = self._create_graph()

    def _create_graph(self):
        """Create graph from tasks

        :return: directed graph
        """
        graph = nx.DiGraph()
        for task in self.tasks:
            task_id = task['id']
            graph.add_node(task_id, **task)
            if 'required_for' in task:
                for req in task['required_for']:
                    graph.add_edge(task_id, req)
            if 'requires' in task:
                for req in task['requires']:
                    graph.add_edge(req, task_id)

            if 'groups' in task:
                for req in task['groups']:
                    # check if group is defined as regular expression
                    if req.startswith('/'):
                       continue
                    graph.add_edge(task_id, req)
            if 'tasks' in task:
                for req in task['tasks']:
                    graph.add_edge(req, task_id)

        return graph

    def find_cycles(self):
        """Find cycles in graph.

        :return: list of cycles in graph
        """
        cycles = []
        for cycle in nx.simple_cycles(self.graph):
            cycles.append(cycle)

        return cycles

    def is_connected(self):
        """Check if graph is connected.

        :return: bool
        """
        return nx.is_weakly_connected(self.graph)

    def find_empty_nodes(self):
        """Find empty nodes in graph.

        :return: list of empty nodes in graph
        """
        empty_nodes = []
        for node_name, node in self.graph.node.items():
            if node == {}:
                empty_nodes.append(node_name)
        return empty_nodes
