# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   grayloginstall::elastic_host { 'namevar': }
define grayloginstall::elastic_host (
  Stdlib::Fqdn
          $hostname     = $::facts['fqdn'],
  Stdlib::IP::Address
          $ip           = $::facts['networking']['ip'],
  Stdlib::Unixpath
          $hosts_target = '/etc/graylog/elasticsearch.hosts',
  String  $cluster_name = 'graylog',
) {
  $elastic_hostname = "elastic.${hostname}"
  host { $elastic_hostname:
    ensure => present,
    ip     => $ip,
    target => $hosts_target,
  }
}
