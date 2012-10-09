Reference Architecture
======================

This reference architecture, combined with Cobbler & Puppet automation, allows you to easily deploy OpenStack in a highly available mode. It means that failure of a single service or even a whole controller machine will not affect your ability to control the cloud. High availability is provided by integrated open source components, including:

* keepalived
* HAProxy
* RabbitMQ
* MySQL/Galera

It’s important to mention that the entire reference architecture is based on active/active mode for relevant components. There are no active/standby elements, and OpenStack deployment can be easily scaled by adding new active nodes if/as needed, whether it’s controllers, compute, or storage. 
