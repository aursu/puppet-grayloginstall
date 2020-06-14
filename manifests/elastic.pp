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
  String  $cluster_name         = 'graylog',
  String  $version              = '6.8.10',
  Grayloginstall::NetworkHost
          $network_host         = '_site_',
  Integer $minimum_master_nodes = 2,

  Array[Stdlib::IP::Address]
          $discovery_seed_hosts = ['127.0.0.1', '::1'],
)
{
  $remote_discovery_seed_hosts = $discovery_seed_hosts.filter |$addr| {
    $addr in ['127.0.0.1', '::1'] or
    ! grayloginstall::selfaddr($addr)
  }
  $config_discovery_seed_hosts = grayloginstall::configaddr($remote_discovery_seed_hosts)

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
      'network.host'                       => $network_host,
      'discovery.zen.ping.unicast.hosts'   => $config_discovery_seed_hosts,
      'discovery.zen.minimum_master_nodes' => $minimum_master_nodes,
    },
  }

  Class['elastic_stack::repo']
      -> Class['elasticsearch::package']
}
