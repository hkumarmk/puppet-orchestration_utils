Puppet::Type.type(:consul_kv_mysql_masterdata).provide(
  :default,
  :parent => Puppet::Type.type(:consul_kv).provider(:default)
) do

  # Without initvars commands won't work.
  initvars
  commands :mysql      => 'mysql'

  # Optional defaults file
  def self.defaults_file
    if File.file?("#{Facter.value(:root_home)}/.my.cnf")
      "--defaults-extra-file=#{Facter.value(:root_home)}/.my.cnf"
    else
      nil
    end
  end

  def kvurl
    'http://localhost:8500/v1/kv'
  end

  def defaults_file
    self.class.defaults_file
  end

  def masterdata
    mysql(defaults_file, '-NBe', "SHOW MASTER STATUS").chomp.split("\t")
  end

  def kvName
    "services/#{resource[:name]}/mysql/masterdata"
  end

  def exists?
    key = getKV(kvName)
    key.nil? ? raise(Puppet::Error,"Failed to get data from consul") : ! key.empty?
  end

  def create
    createKV(kvName,masterdata[0],
      {
        :flags   => masterdata[1],
        :cas     => 0,
      }
    )
  end

  def destroy
    deleteKV(kvName)
  end

end
