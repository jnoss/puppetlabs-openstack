# A profile for installing both a Swift Proxy and a single loopback storage node on one box
class havana::profile::swift::both (
    $zone = undef,
  ) {
#--------------------[ storage ]-------------------------------------------------
    $management_network = hiera('openstack::network::management')
    $management_address = ip_for_network($management_network)

    firewall { '6000 - Swift Object Store':
      proto  => 'tcp',
      state  => ['NEW'],
      action => 'accept',
      port   => '',
    }

    firewall { '6001 - Swift Container Store':
      proto  => 'tcp',
      state  => ['NEW'],
      action => 'accept',
      port   => '6001',
    }

    firewall { '6002 - Swift Account Store':
      proto  => 'tcp',
      state  => ['NEW'],
      action => 'accept',
      port   => '6002',
    }

    class { '::swift':
      swift_hash_suffix => hiera('openstack::swift::hash_suffix'),
    }

    swift::storage::loopback { '1':
      base_dir     => '/srv/swift-loopback',
      mnt_base_dir => '/srv/node',
      byte_size    => 1024,
      seek         => 10000,
      fstype       => 'ext4',
      require      => Class['swift'],
    }

    class { '::swift::storage::all':
      storage_local_net_ip => $management_address
    }

    @@ring_object_device { "${management_address}:6000/1":
      zone   => $zone,
      weight => 1,
    }

    @@ring_container_device { "${management_address}:6001/1":
      zone   => $zone,
      weight => 1,
    }

    @@ring_account_device { "${management_address}:6002/1":
      zone   => $zone,
      weight => 1,
    }

    swift::ringsync { ['account','container','object']: 
      ring_server => hiera('openstack::controller::address::management'), 
    }

#--------------------[ proxy ]-------------------------------------------------

  ::havana::resources::controller { 'swift': }
  ::havana::resources::firewall { 'Swift Proxy': port => '8080', }

  class { '::swift::keystone::auth':
    password         => hiera('openstack::swift::password'),
    public_address   => hiera('openstack::controller::address::api'),
    admin_address    => hiera('openstack::controller::address::management'),
    internal_address => hiera('openstack::controller::address::management'),
    region           => hiera('openstack::region'),
  }

  # sets up the proxy service
  class { '::swift::proxy':
    proxy_local_net_ip => hiera('openstack::controller::address::api'),
    pipeline           => ['catch_errors', 'healthcheck', 'cache',
                           'ratelimit',    'swift3',
                           'authtoken',    'keystone',    'proxy-server'],
    workers            => 1,
    require            => Class['::swift::ringbuilder'],
  }

  ### BEGIN Middleware Configuration (declared in pipeline for proxy)
  class { ['::swift::proxy::catch_errors',
           '::swift::proxy::healthcheck', ]: }

  class { '::swift::proxy::cache':
    memcache_servers => [ hiera('openstack::controller::address::management'), ]
  }

  class { ['::swift::proxy::ratelimit',
           '::swift::proxy::swift3', ]: }

  class { '::swift::proxy::authtoken':
    admin_password => hiera('openstack::swift::password'),
    auth_host      => hiera('openstack::controller::address::management'),
  }

  class { '::swift::proxy::keystone': }

  ### END Middleware Configuration

  # collect all of the resources that are needed to balance the ring
  Ring_object_device <<| |>>
  Ring_container_device <<| |>>
  Ring_account_device <<| |>>

  class { '::swift::ringbuilder':
    part_power     => 18,
    replicas       => 3,
    min_part_hours => 1,
    require        => Class['::swift'],
  }

  class { '::swift::ringserver':
    local_net_ip => hiera('openstack::controller::address::management'),
  }

}
