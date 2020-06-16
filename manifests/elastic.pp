# @summary Configure elasticsearch for use with Graylog
#
# @example Basic usage
#   class { 'grayloginstall::elastic':
#     network_host         => '_eth1:ipv4_',
#     discovery_seed_hosts => ['192.168.178.10', '192.168.178.20'],
#   }
#
# @see https://docs.graylog.org/en/3.3/pages/installation/os/centos.html#elasticsearch
#
# @param version
#   Elasticsearch version (Graylog 3 does not work with Elasticsearch 7.x)
#
# @param network_host
#   The node will bind to this hostname or IP address and publish (advertise) this host to other nodes in the cluster. Accepts
#   an IP address, hostname, a special value.
#   Default is _site_ (any site-local addresses on the system, for example 192.168.0.1)
#   See https://www.elastic.co/guide/en/elasticsearch/reference/6.8/modules-network.html#network-interface-values
#
# @param minimum_master_nodes
#   it is vital to configure the discovery.zen.minimum_master_nodes setting so that each master-eligible node knows the minimum
#   number of master-eligible nodes that must be visible in order to form a cluster.
#   Default is 2 (avoiding split brain in case of 2-3 nodes)
#   See https://www.elastic.co/guide/en/elasticsearch/reference/6.8/discovery-settings.html#minimum_master_nodes
#
# @param discovery_seed_hosts
#   seed list of other nodes in the cluster.
#   Default is ["127.0.0.1", "[::1]"] - elasticsearch will bind to the available loopback addresses and will scan ports 9300
#   to 9305 to try to connect to other nodes running on the same server
#   See https://www.elastic.co/guide/en/elasticsearch/reference/6.8/discovery-settings.html#unicast.hosts
#
class grayloginstall::elastic (
  String  $version              = $grayloginstall::params::elastic_version,
  Integer $minimum_master_nodes = 2,
  String  $cluster_name         = 'graylog',
  Optional[Grayloginstall::NetworkHost]
          $network_host         = undef,
  Optional[Array[Stdlib::IP::Address]]
          $discovery_seed_hosts = undef,
) inherits grayloginstall::params
{
  include grayloginstall::cluster

  $default_discovery_seed_hosts = $grayloginstall::params::elastic_discovery_seed_hosts
  $cluster_network_host         = $grayloginstall::cluster::ipaddr
  $cluster_discovery_seed_hosts = $grayloginstall::cluster::elastic_seed_hosts

  # parameter network_host has higher priority over cluster settings
  if $network_host {
    $config_network_host = $network_host
  }
  # IP address of network interface that belongs to subnet specified via grayloginstall::cluster::subnet
  # if subnet is not specified - default IP address (IP address of inerface that default route set to)
  # Undef if grayloginstall::cluster::fallback_default is false and cluster subnet is  not specified
  elsif $cluster_network_host {
    $config_network_host = $cluster_network_host
  }
  else {
    # fallback to module default
    $config_network_host = $grayloginstall::params::elastic_network_host
  }

  # handle provided discovery seed hosts first
  if $discovery_seed_hosts and $discovery_seed_hosts[0] {
    $remote_discovery_seed_hosts = $discovery_seed_hosts.filter |$addr| {
      # filter out local (self) addresses and loopbacks
      ! grayloginstall::selfaddr($addr)
    }
  }
  else {
    $remote_discovery_seed_hosts = []
  }

  if $remote_discovery_seed_hosts[0]  {
    $config_discovery_seed_hosts = grayloginstall::configaddr($remote_discovery_seed_hosts)
  }
  # use cluster discovery settings
  elsif $cluster_discovery_seed_hosts[0] {
    $config_discovery_seed_hosts = grayloginstall::configaddr($cluster_discovery_seed_hosts)
  }
  else {
    # fallback  to default value if cluster not exists
    $config_discovery_seed_hosts = grayloginstall::configaddr($default_discovery_seed_hosts)
  }

  # https://www.elastic.co/guide/en/elasticsearch/reference/6.7/rpm.html
  class { 'elasticsearch':
    version           => $version,
    manage_repo       => false,
    config            => {
      'cluster.name'             => $cluster_name,
      'action.auto_create_index' => '.watches,.triggered_watches,.watcher-history-*',
    },
    restart_on_change => true
  }

  class { 'elastic_stack::repo':
    version => 6,
  }

  # file resource to not purge repo in case if /etc/yum.repos.d are managed with purge => true
  file { '/etc/yum.repos.d/elastic.repo':
    mode => '0600',
  }

  elasticsearch::instance { 'graylog':
    config => {
      'network.host'                       => $config_network_host,
      'discovery.zen.ping.unicast.hosts'   => $config_discovery_seed_hosts,
      'discovery.zen.minimum_master_nodes' => $minimum_master_nodes,
    },
  }

  Class['elastic_stack::repo']
      -> Class['elasticsearch::package']
}
