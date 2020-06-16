# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   grayloginstall::elastic_host { 'namevar': }
define grayloginstall::elastic_host (
  Stdlib::IP::Address
          $ip,
  String  $cluster_name,
  Stdlib::Fqdn
          $hostname     = $::facts['fqdn'],
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
