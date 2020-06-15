require 'ipaddr'

Puppet::Functions.create_function(:'grayloginstall::selfaddr') do
  dispatch :selfaddr do
    param 'String', :addr
    return_type 'Boolean'
  end

  def validate_ip(ip)
    return nil unless ip
    IPAddr.new(ip)
  rescue ArgumentError
    nil
  end

  def selfaddr(addr)
    raise ArgumentError, "'grayloginstall::rb_selfaddr' parameter 'addr' expects a Stdlib::IP::Address value, got #{addr.inspect}" unless validate_ip(addr)

    facts = closure_scope['facts']
    interfaces = facts['networking']['interfaces'].select { |_iface, data| data['ip'] || data['ip6'] }

    ip = interfaces.map { |_iface, data| data['ip'] }
    ip6 = interfaces.map { |_iface, data| data['ip6'] }

    (ip + ip6).include?(addr) || (addr == '::1') || IPAddr.new('127.0.0.0/8').include?(addr)
  end
end
