#!/usr/bin/env python
"""Tests for YAQL expressions in Fuel tasks.yaml files
Load and evaluate YAQL expressions from tasks.
Usage:
    check_yaqls.py [--dir DIRPATH] [--fixtures FIXT_DIR] [--cluster CLUSTER_ID] [--node NODE_ID]
    check_yaqls.py --file FILEPATH [--fixtures FIXT_DIR] [--cluster CLUSTER_ID] [--node NODE_ID]
    check_yaqls.py -h
    check_yaqls.py --version

Options:
    -d --dir DIRPATH        try to load all YAQL expressions from all tasks.yaml files found in directory and subdirectories [default: ../../deployment]
    -f --file FILEPATH      try to load all expressions from file
    -x --fixtures FIXT_DIR  use this directory to load fixtures from [default: fixtures]
    -c --cluster CLUSTER_ID use this cluster ID [default: 1]
    -n --node NODE_ID       use this node [default: 1]
    -h --help               show this help
    --version               show version
"""
import collections
import json
import logging
import os
import sys
import traceback
import yaml

from docopt import docopt
from nailgun.fuyaql import fuyaql

TEST_FAILED = False
options = docopt(__doc__, version='0.1')


def load_tasks_from_directory(directory):
    """Loads tasks from dir and subdirs.

    :param directory: directory from which tasks will be loaded
    :return: dict with task names as keys and task expressions as values
    """
    tasks_list = []
    for root, dirs, files in os.walk(directory):
        for filename in files:
            if filename == 'tasks.yaml':
                 tasks_list.append(os.path.join(root, filename))

    tasks_conditions = dict()
    for tasks in tasks_list:
        tasks_conditions.update(load_tasks_from_file(tasks))
    return tasks_conditions


def load_tasks_from_file(tasks_file):
    """Loads tasks from file.

    :param tasks_file: file from which tasks will be loaded
    :return: dict with task names as keys and task expressions as values
    """
    tasks_conditions = dict()
    with open(tasks_file, 'rt') as f:
        yml = yaml.safe_load(f)
    tasks_conditions.update(
        {t['id']: t.get('condition', {}).get('yaql_exp', {}) for t in yml})
    return tasks_conditions


def load_tasks():
    """Load tasks from directory or file

    :return: hash with tasks names and conditions
    """
    if not options['--file']:
        current_dir = os.path.dirname(os.path.realpath(__file__))
        deployment_dir = current_dir + "/" + options['--dir']
        print('deployment dir is %s' % deployment_dir)
        tasks = load_tasks_from_directory(deployment_dir)
    else:
        tasks_file = options['--file']
        tasks = load_tasks_from_file(tasks_file)
    return tasks


def get_logger():
    """Get a logger and disable DEBUG state

    :return: logger instance
    """
    logger = logging.getLogger(__name__)
    logger.propagate = False
    logging.disable(logging.DEBUG)
    return logger


def get_evaluator():
    """Get a YAQL evaluator

    :return: FuYaqlController evaluator instance
    """
    evaluator = fuyaql.FuYaqlController()
    evaluator._cluster = True
    evaluator._node_id = options['--node']
    return evaluator


def set_evaluator_data(evaluator, old_context, new_context):
    """Set evaluator data

    :param evaluator: FuYaqlController evaluator instance
    :param old_context: hash to use as an old context
    :param new_context: hash to use as a new context
    """
    try:
        with open(os.path.expanduser(old_context), 'r') as f:
            current_state = json.load(f)
        with open(os.path.expanduser(new_context), 'r') as f:
            expected_state = json.load(f)
    except IOError:
        print("Cannot open context fixtures file.")
        print(traceback.format_exc())
        sys.exit(1)
    evaluator._infos = current_state, expected_state


def load_fixtures_from_directory(directory):
    """Recursively load fixture sets from directory

    :param directory: path to a directory with fixtures
    :return: dictionary with fixtures name and path to context files
    """
    fixtures = collections.defaultdict(dict)
    for root, dirs, files in os.walk(directory):
        for filename in files:
            if filename.endswith('_old_context.json'):
                base_name = filename.split('_old_context.json')[0]
                fixtures[base_name]['old'] = os.path.join(root, filename)
            elif filename.endswith('_new_context.json'):
                base_name = filename.split('_new_context.json')[0]
                fixtures[base_name]['new'] = os.path.join(root, filename)
    return fixtures


tasks = load_tasks()
logger = get_logger()
evaluator = get_evaluator()
fixtures = load_fixtures_from_directory(options['--fixtures'])


for basename, files_hash in fixtures.items():
    print("Start evaluating for {} context".format(basename))
    set_evaluator_data(evaluator, files_hash['old'], files_hash['new'])
    failed_tasks = dict()

    for task_name, expression in tasks.items():
        # There are tasks without yaql_expressions
        if not expression:
            continue
        try:
            res = evaluator.evaluate(expression)
            print("Expression for %s task looks valid" % task_name)
        except Exception as e:
            print("Expression for %s task doesn't looks valid" % task_name)
            print("%s" % expression)
            print(traceback.format_exc())
            failed_tasks[task_name] = 'Fail'

    if failed_tasks:
        print('*'*20 + ' List of failed tasks ' + '*'*20)
        for name in failed_tasks:
            print(name)
        TEST_FAILED = True

if TEST_FAILED:
    print("Some tasks failed, check the output")
    sys.exit(1)

print('*'*20 + ' There is no failed tasks ' + '*'*20)




