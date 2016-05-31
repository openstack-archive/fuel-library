#!/usr/bin/env python
"""Tests for YAQL expressions in Fuel tasks.yaml files
Load and evaluate YAQL expressions from tasks.
Usage:
    check_yaqls.py [--dir DIRPATH] [--fixtures FIXT_DIR]
    check_yaqls.py --file FILEPATH [--fixtures FIXT_DIR]
    check_yaqls.py -h
    check_yaqls.py --version

Options:
    -d --dir DIRPATH        try to load all YAQL expressions from all tasks.yaml files found in directory and subdirectories [default: ../../deployment]
    -f --file FILEPATH      try to load all expressions from file
    -x --fixtures FIXT_DIR  use this directory to load fixtures from [default: fixtures]
    -h --help               show this help
    --version               show version
"""
import json
import logging
import os
import sys
import traceback
import yaml
from docopt import docopt
from fuelyaql import fuyaql


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


if not options['--file']:
    current_dir = os.path.dirname(os.path.realpath(__file__))
    deployment_dir = current_dir + options['--dir']
    tasks = load_tasks_from_directory(options['--dir'])
else:
    tasks_file = options['--file']
    tasks = load_tasks_from_file(tasks_file)

# As fuel-yaql needed some attributes, we change options dicts
options['CLUSTER_ID'] = 1
options['--node'] = 'master'

logger = logging.getLogger(__name__)
logger.propagate = False
logging.disable(logging.DEBUG)
evaluator = fuyaql.Fyaql(options, logger)
try:
    fixtures_path = evaluator.options['--fixtures']
    with open(os.path.expanduser(fixtures_path + '/old_context.json'),
              'r') as f:
        current_state = json.load(f)
    with open(os.path.expanduser(fixtures_path + '/new_context.json'),
              'r') as f:
        expected_state = json.load(f)
except IOError:
    print("Cannot open context fixtures file.")
    sys.exit(1)
evaluator.get_contexts()
evaluator.context['$%new'] = expected_state
evaluator.context['$%old'] = current_state
evaluator.create_evaluator()

failed_tasks = dict()
for task_name, expression in tasks.items():
    # There are tasks without yaql_expressions
    if not expression:
        continue
    try:
        parsed_exp = evaluator.yaql_engine(expression)
        res = parsed_exp.evaluate(data=evaluator.context['$%new'],
                                  context=evaluator.context)
        print("Expression for %s task looks valid" % task_name)
        print("")
    except Exception as e:
        print("Expression for %s task doesn't looks valid" % task_name)
        print("%s" % expression)
        print(traceback.format_exc())
        failed_tasks[task_name] = 'Fail'

if failed_tasks:
    print('*'*20 + ' List of failed tasks ' + '*'*20)
    for name in failed_tasks.keys():
        print(name)
    sys.exit(1)

print('*'*20 + ' There is no failed tasks ' + '*'*20)




