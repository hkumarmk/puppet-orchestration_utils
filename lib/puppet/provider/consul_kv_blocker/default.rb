require 'puppet/provider/blocker'

Puppet::Type.type(:consul_kv_blocker).provide(
  :default,
  :parent => Puppet::Provider::Blocker
) do

  def connect(url)
    @uri ||= URI(url)
    @http ||= Net::HTTP.new(@uri.host, @uri.port)
  end

  def getKey(url,key)
    @value ||=''
    if @value.empty?
      connect(url)
      path=@uri.request_uri + '/'  + key
      req = Net::HTTP::Get.new(path)
      res = @http.request(req)
      if res.code == '200'
        data = JSON.parse(res.body)
        @value = Base64.decode64(JSON.parse(res.body)[0]['Value'])
      elsif res.code == '404'
      else
        raise(Puppet::Error,"Uri: #{@uri.to_s}/#{key} returned invalid return code #{res.code}")
      end
    end
    return @value
  end

  def ready
    result = block_until_ready do
      debug("Trying to fetch Consul K/V: #{resource[:name]}")
      value = getKey(resource[:url],resource[:name])
      if !value.empty?
        debug("Found Key: #{value}")
        return true
      end
    end
    fail("Could not find Consul KV - #{resource[:name]}")
  end

  def ready=(val)
    # do nothing
  end

end
