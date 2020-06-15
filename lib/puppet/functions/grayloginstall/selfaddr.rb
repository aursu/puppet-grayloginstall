require 'ipaddr'

Puppet::Functions.create_function(:'grayloginstall::selfaddr') do
  dispatch :selfaddr do
    param 'String', :addr
    optional_param 'String', :subnet
    return_type 'Boolean'
  end

  def validate_ip(ip)
    return nil unless ip
    IPAddr.new(ip)
  rescue ArgumentError
    nil
  end

  def selfaddr(addr)
    raise ArgumentError, "'grayloginstall::selfaddr' parameter 'addr' expects a Stdlib::IP::Address value, got #{addr.inspect}" unless validate_ip(addr)

    facts = closure_scope.lookupvar('facts')
    interfaces = facts['networking']['interfaces'].select { |iface, data| data['ip'] || data['ip6'] }

    ip = interfaces.map { |iface, data| data['ip'] }
    ip6 = interfaces.map { |iface, data| data['ip6'] }

    (ip + ip6).include? (addr)
  end
end