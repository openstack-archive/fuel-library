A closer look at the Multi-node (HA) Compact deployment
-------------------------------------------------------

In this section, you'll learn more about the Multi-node (HA) Compact
deployment configuration and how it achieves high availability in preparation
for installing this cluster in section 3. As you may recall, this
configuration looks something like this:

.. image:: https://docs.google.com/drawings/d/1xLv4zog19j0MThVGV9gSYa4wh1Ma4MQYsBz-4vE1xvg/pub?w=767&h=413


OpenStack services are interconnected by RESTful HTTP-based APIs and
AMQP-based RPC messages. So redundancy for stateless OpenStack API
services is implemented through the combination of Virtual IP (VIP)
management using keepalived and load balancing using HAProxy. Stateful
OpenStack components, such as the state database and messaging server,
rely on their respective active/active modes for high availability.
For example, RabbitMQ uses built-in clustering capabilities, while the
database uses MySQL/Galera replication.

.. image:: https://docs.google.com/drawings/pub?id=1PzRBUaZEPMG25488mlb42fRdlFS3BygPwbAGBHudnTM&w=750&h=491

Lets take a closer look at what an OpenStack deployment looks like, and
what it will take to achieve high availability for an OpenStack
deployment.

