Puppet::Functions.create_function(:'grayloginstall::discovery_hosts', Puppet::Functions::InternalFunction) do
  dispatch :discovery_hosts do
    scope_param
    param 'String', :lookup_type
    optional_param 'String', :lookup_param
  end

  def discovery_hosts(scope, lookup_type, lookup_param = nil)
    resources = scope.compiler.resources.select { |r| r.type == lookup_type }.reject { |r| r.exported? }
      if lookup_param.nil?
        resources.map { |r| r.title.to_s }
      else
        p = lookup_param.to_sym
        resources.reject { |r| r[p].nil? }.map { |r| r[p].to_s }
      end
  end
end
