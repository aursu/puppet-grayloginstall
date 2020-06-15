function grayloginstall::selfaddr(Stdlib::IP::Address $addr) >> Boolean {
  $interfaces = $::facts['networking']['interfaces'].filter |$iface| { $iface[1]['ip'] =~ Stdlib::IP::Address }

  $ip = $interfaces.map |$iface, $data| { $data['ip'] }
  $ip6 = $interfaces.map |$iface, $data| { $data['ip6'] }

  $addr in $ip or $addr in $ip6
}
