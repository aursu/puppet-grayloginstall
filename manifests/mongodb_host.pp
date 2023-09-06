# @summary MongoDB resource to export into PuppetDB
#
# MongoDB resource to export into PuppetDB
#
# @example
#   grayloginstall::mongodb_host { 'namevar': }
define grayloginstall::mongodb_host (
  Stdlib::IP::Address
          $ip,
  String  $cluster_name,
  Stdlib::Fqdn
          $hostname     = $facts['networking']['fqdn'],
  Stdlib::Unixpath
          $hosts_target = '/etc/graylog/mongodb.hosts',
) {
  $mongodb_hostname = "mongodb.${hostname}"
  host { $mongodb_hostname:
    ensure => present,
    ip     => $ip,
    target => $hosts_target,
  }
}
