#!/bin/bash
# Mount the openstack module on the Puppet Master
vagrant ssh puppet -c "sudo ln -s /openstack /etc/puppet/modules; \
sudo ln -s /openstack/examples/rhel_multinode/hiera.yaml /etc/puppet/hiera.yaml; \
sudo mkdir -p /etc/puppet/hieradata; \
sudo ln -s /openstack/examples/rhel_multinode/openstack.yaml /etc/puppet/hieradata/common.yaml; \
sudo service puppetmaster restart;"
