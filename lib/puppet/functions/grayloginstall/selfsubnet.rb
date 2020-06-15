require 'ipaddr'

Puppet::Functions.create_function(:'grayloginstall::selfsubnet') do
  dispatch :selfsubnet do
    param 'String', :subnet
  end

  def validate_ip(ip)
    return nil unless ip
    IPAddr.new(ip)
  rescue ArgumentError
    nil
  end

  def selfsubnet(subnet)
    subnet = validate_ip(subnet)
    raise ArgumentError, "'grayloginstall::selfsubnet' parameter 'subnet' expects a Stdlib::IP::Address value, got #{subnet.inspect}" if subnet.nil?

    facts = closure_scope['facts']
    interfaces = facts['networking']['interfaces'].select { |iface, data| data['ip'] || data['ip6'] }

    ip = interfaces.map { |iface, data| data['ip'] }
    ip6 = interfaces.map { |iface, data| data['ip6'] }

    (ip + ip6).select { |addr| subnet.include?(addr) }
  end
end