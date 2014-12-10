module Puppet::Parser::Functions
  newfunction(
    :easy_host,
    :type => :statement,
    :doc => <<-'EOD'
  Accept hash of name and IP and add entries in /etc/hosts.

    easy_host({'node1.example.com' => '10.1.1.1',
              'node2.example.com' => '10.1.1.2',
              'node3  => '10.1.1.3' })

  The above example will make two /etc/hosts entries as follows
  10.1.1.1  node1.example.com node1
  10.1.1.2  node2.example.com node2
  10.1.1.3  node3
EOD
  ) do |args|
    raise(ArgumentError, 'Argument must be a hash') unless args[0].is_a?(Hash)
    args[0].each do |fqdn,ip|
      fqdn =~ /^([\w-]+)\.\S+/
      hostname = $1
      input_hash = {}
      if fqdn.eql? hostname
        input_hash = {'name' => fqdn, 'ip' => ip }
      else
        input_hash = {'name' => fqdn, 'ip' => ip, 'host_aliases' => hostname}
      end
      Puppet::Parser::Functions.function(:ensure_resource)
      function_ensure_resource(['Host', fqdn, input_hash])
    end
  end
end
