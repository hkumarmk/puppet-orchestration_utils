Puppet::Type.newtype(:consul_kv_mysql_slave_update) do

  @doc = <<-'EOD'
  Create consul kv for mysql master data.
  e.g
  Add a key/value pair or change value of a key

  consul_kv_mysql_slave_update{'test': }

  Above code will create a key in consul named
'mysql_replication/binfile' and  with value binfile name and with flag binlog
position which is retried from master status on mysql master. This should only
be run on master mysql server and will enable automatically setup mysql
replication.
  EOD

  ensurable do
    defaultvalues
    defaultto :present
  end

  newparam(:name, :namevar => true) do
    desc  'Mysql db server instance name - mysql slave will look the path
includes this name'
  end

  newparam(:repl_user) do
    desc 'Mysql username for replication'
  end

  newparam(:repl_password) do
    desc 'Mysql password for replication'
  end


end
