import os
import yaml

current_dir = os.path.dirname(os.path.realpath(__file__))
print(current_dir)
deployment_dir = current_dir + '/../../deployment'
print(deployment_dir)

tasks_list = []
for root, dirs, files in os.walk(deployment_dir):
    for filename in files:
        if filename == 'tasks.yaml':
             tasks_list.append(os.path.join(root, filename))

tasks_conditions = dict()
for tasks in tasks_list:
    print(tasks)
    with open(tasks, 'rt') as f:
        yml = yaml.safe_load(f)
    tasks_conditions.update(
        {t['id']: t.get('condition', {}).get('yaql_exp', {}) for t in yml})

print(tasks_conditions)


