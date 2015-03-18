user { 'vagrant':
  ensure   => present,
  name     => 'vagrant',
  password => '$1$lmbBNjqr$93KEmhex2A3Hsal6.muEc/',
}


node 'puppet' {
  include ::ntp
}

node 'control.localdomain' {
  include ::openstack::role::controller
}

node 'storage.localdomain' {
  include ::openstack::role::storage
}

node 'network.localdomain' {
  include ::openstack::role::network
}

node 'compute.localdomain' {
  include ::openstack::role::compute
}

