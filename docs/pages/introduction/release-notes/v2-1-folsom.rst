
v2.1-folsom
^^^^^^^^^^^

* Features

  * Support deploying Quantum on controller nodes, as well as on a dedicated networking node
  * Active/Standby HA for Quantum with Pacemaker when Quantum is deployed on controller nodes
  * Logging: an option to send OpenStack logs to local and remote locations through syslog
  * Monitoring: deployment of Nagios, health checks for infrastructure components (OpenStack API, MySQL, RabbitMQ)
  * Installation of Puppet Master & Cobbler Server node from ISO
  * Deployment orchestration based on mcollective eliminates the need to run Puppet manually on each node
  * Recommended master node setup for mid-scale deployments, tested up to 100 nodes

* Improvements

  * Support for multiple environments from a single Fuel master node
  * RabbitMQ service moved behind HAProxy to make controller failures transparent to the clients
  * Updated RabbitMQ to 2.8.7 to improve handling on expired HA queues under Ubuntu
  * Changed RabbitMQ init script to automatically reassemble RabbitMQ cluster after failures
  * Configurable HTTP vs. HTTPS for Horizon
  * Changed mirror type option to either be 'default' (installation from the internet) or 'custom' (installation from a local mirror containing packages)
  * Option to allow cinder-volume deployment on controller nodes as well as compute nodes

