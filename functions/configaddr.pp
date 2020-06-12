function grayloginstall::configaddr(Variant[String, Array[String]] $addr) {
  case $addr {
    Array[String]: {
      $addr.map |$ip| {
          $ip ? {
            Stdlib::IP::Address::V6::Nosubnet => ['[', $ip, ']'].join(''),
            default => $ip,
          }
      }
    }
    default: {
      $addr ? {
        Stdlib::IP::Address::V6::Nosubnet => ['[', $addr, ']'].join(''),
        default => $addr,
      }
    }
  }
}
