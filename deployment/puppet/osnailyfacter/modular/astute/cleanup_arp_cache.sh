#!/bin/sh

# Clean up the neighbor table (ARP/NDISC cache)
/sbin/ip -s -s neigh flush all
