# @summary Elasticsearch resource to export into PuppetDB
#
# Elasticsearch resource to export into PuppetDB
#
# @example
#   grayloginstall::elastic_host { 'namevar': }
define grayloginstall::elastic_host (
  Stdlib::IP::Address
          $ip,
  String  $cluster_name,
  Stdlib::Fqdn
          $hostname     = $facts['networking']['fqdn'],
  Stdlib::Unixpath
          $hosts_target = '/etc/graylog/elasticsearch.hosts',
) {
  $elastic_hostname = "elastic.${hostname}"
  host { $elastic_hostname:
    ensure => present,
    ip     => $ip,
    target => $hosts_target,
  }
}
