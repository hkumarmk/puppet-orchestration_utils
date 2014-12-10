require 'net/http'
require 'uri'
require 'json'

module Puppet::Parser::Functions
  newfunction(
    :service_discover_consul,
    :type  => :rvalue,
    :doc   => <<-'EOS'

Given the name of a service and optionally, a tag, this function
returns a hash of the form:
  (name => ip_address)
for each host that registered that service in consul

EOS
  ) do |args|
    name = args.shift
    tag  = args.shift
    raise(ArgumentError, "name must be specified") unless name
    consul_host = args.shift || '127.0.0.1'
    consul_port = args.shift || '8500'
    tag_query = tag ? "?tag=#{tag}" : ''
    uri = URI("http://#{consul_host}:#{consul_port}/v1/catalog/service/#{name}#{tag_query}")
    res = Net::HTTP.get_response(uri)
    if res.code == '200'
      results = JSON.parse(res.body)
      ret_hash = {}
      results.each do |node|
        ret_hash[node['Node']] = node['Address']
      end
      ret_hash
    else
      raise(Puppet::Error, "Uri: #{uri.to_s}, returned code #{res.code}")
    end
  end
end
