# @summary A short summary of the purpose of this class
#
# A description of what this class does
#
# @example
#   include grayloginstall::cluster
class grayloginstall::cluster (
  String  $cluster_name     = $grayloginstall::params::cluster_name,
  Boolean $fallback_default = true,
  Optional[Stdlib::IP::Address]
          $subnet           = undef,
) inherits grayloginstall::params
{
  $hostname = $::facts['fqdn']

  if $subnet {
    $addr = grayloginstall::selfsubnet($subnet)
  }
  else {
    $addr = []
  }

  if $addr[0] {
    # pick first address out of set
    $ipaddr = $addr[0]
  }
  else {
    if $fallback_default {
      # fallback to default interface (not safe if it is public)
      $ipaddr = $::facts['networking']['ip']
    }
    else {
      $ipaddr = undef
    }
  }

  if $ipaddr {
    # elastic export
    @@grayloginstall::elastic_host { $hostname:
      cluster_name => $cluster_name,
      ip           => $ipaddr,
      hostname     => $hostname,
    }

    # mongo export
    @@grayloginstall::mongodb_host { $hostname:
      cluster_name => $cluster_name,
      ip           => $ipaddr,
      hostname     => $hostname,
    }
  }

  Grayloginstall::Elastic_host <<| cluster_name == $cluster_name |>>
  Grayloginstall::Mongodb_host <<| cluster_name == $cluster_name |>>

  $mongo_discovery   = grayloginstall::discovery_hosts('Grayloginstall::Mongodb_host', 'ip', ['cluster_name', '==', $cluster_name])

  $elastic_discovery = grayloginstall::discovery_hosts('Grayloginstall::Elastic_host', 'ip', ['cluster_name', '==', $cluster_name])
  $elastic_seed_hosts = $elastic_discovery.filter |$addr| { ! grayloginstall::selfaddr($addr) }
}
