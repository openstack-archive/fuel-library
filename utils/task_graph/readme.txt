usage: task_graph.py [-h] [--workbook] [--clear_workbook] [--dot] [--png]
                     [--png_file PNG_FILE] [--debug] [--group GROUP]
                     [--topology]
                     FILE [FILE ...]

positional arguments:
  FILE                  The list of files of directories where tasks can be
                        found

optional arguments:
  -h, --help            show this help message and exit
  --workbook, -w        Output the raw workbook
  --clear_workbook, -c  Output the clear workbook
  --dot, -o             Output the graph in dot format
  --png, -p             Write the graph in png format (default)
  --png_file PNG_FILE, -f PNG_FILE
                        Write graph image to this file
  --debug, -d           Print debug messages
  --group GROUP, -g GROUP
                        Group or stage to build the graph for
  --topology, -t        Show the tasks topology (possible execution order)

This tools can be used to create a task graph image. Just pouint it
at the folder where tasks.yaml files can be found.

> utils/task_graph/task_graph.py deployment/puppet/osnailyfacter/modular

It will create task_graph.png file in the current directroy.

You can also use -w and -c options to inspect the workbook yamls
files and output graph as graphviz file with -o option.

You can filter graph by roles and stages with -g option like this
> utils/task_graph/task_graph.py -g post_deployment deployment/puppet/osnailyfacter/modular

And you can use -t option to view the possible order of task execution
with the current graph.

> utils/task_graph/task_graph.py -t deployment/puppet/osnailyfacter/modular

1   hiera                  primary-controller, controller, cinder, compute, ceph-osd, zabbix-server, primary-mongo, mongo
2   globals                primary-controller, controller, cinder, compute, ceph-osd, zabbix-server, primary-mongo, mongo
3   logging                primary-controller, controller, cinder, compute, ceph-osd, zabbix-server, primary-mongo, mongo
4   netconfig              primary-controller, controller, cinder, compute, ceph-osd, zabbix-server, primary-mongo, mongo
5   firewall               primary-controller, controller, cinder, compute, ceph-osd, zabbix-server, primary-mongo, mongo
6   hosts                  primary-controller, controller, cinder, compute, ceph-osd, zabbix-server, primary-mongo, mongo
7   top-role-compute       compute
8   top-role-primary-mongo primary-mongo
9   top-role-mongo         mongo
10  cluster                primary-controller, controller
11  virtual_ips            primary-controller, controller
12  zabbix                 primary-controller, controller, cinder, compute, ceph-osd, zabbix-server, primary-mongo, mongo
13  top-role-ceph-osd      ceph-osd
14  top-role-cinder        cinder
15  tools                  primary-controller, controller, cinder, compute, ceph-osd, zabbix-server, primary-mongo, mongo
16  top-role-controller    primary-controller, controller

