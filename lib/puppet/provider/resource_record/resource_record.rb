# frozen_string_literal: true

require 'ipaddr'
Puppet::Type.type(:resource_record).provide(:ruby) do
  mk_resource_methods

  def initialize(value = {})
    super(value)
    @property_flush = {}
    system('rndc', 'dumpdb', '-zones')
  end

  def self.parse_records
    Puppet.debug('Parsing dump for existing resource records...')
    records = []
    currentzone = ''
    # FIXME: location varies based on config/OS
    File.readlines('/var/cache/bind/named_dump.db').each do |line|
      if line[0] == ';' && line.length > 18
        currentzone = line[/(?:.*?')(.*?)\//, 1]
        if currentzone.respond_to?(:to_str); currentzone = currentzone.downcase end
        Puppet.debug("current zone updated: #{currentzone}")
      elsif line[0] != ';'
        line = line.strip.split(' ', 5)
        rr = {}
        rr[:label] = line[0]
        if rr[:label].respond_to?(:to_str); rr[:label] = rr[:label].downcase.strip end
        Puppet.debug("----New RR---- label: #{rr[:label]}")
        rr[:ttl] = line[1]
        Puppet.debug("RR TTL: #{rr[:ttl]}")
        rr[:scope] = line[2]
        Puppet.debug("RR scope: #{rr[:scope]}")
        rr[:type] = line[3]
        Puppet.debug("RR type: #{rr[:type]}")
        if line[4].respond_to?(:to_str)
          rr[:data] = line[4].tr('\"', '')
        else
          rr[:data] = line[4]
        end
        Puppet.debug("RR data: #{rr[:data]}")
        rr[:zone] = currentzone + '.'
        Puppet.debug("RR zone: #{rr[:zone]}")
        records << {
          title: "#{rr[:label]} #{rr[:zone]} #{rr[:type]} #{rr[:data]}",
          ensure: 'present',
          record: "#{rr[:label]}",
          zone:   "#{rr[:zone]}",
          type:   "#{rr[:type]}",
          data:   "#{rr[:data]}",
          ttl:    "#{rr[:ttl]}",
        }
      end
    end
    Puppet.debug("#{records.inspect}")
    records
  end

  def self.instances
    parse_records
  end

  def create
    @property_flush[:ensure] = :present
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if (resource = resources[prov.title])
        resource.provider = prov
      end
    end
  end

  def flush
    if @property_flush[:ensure] == :absent
      # Delete record
      Puppet.notice("Deleting '#{resource}'")
      cmd = "echo 'zone #{resource[:zone]}
      update delete #{resource[:record]} #{resource[:type]} #{resource[:data]}
      send
      quit
      ' | nsupdate -4 -l"
      system(cmd)
    end
 
    # Create record
    Puppet.notice("Creating '#{resource[:name]}'")
    cmd = "echo 'zone #{resource[:zone]}
    update add #{resource[:record]} #{resource[:ttl]} #{resource[:type]} #{resource[:data]}
    send
    quit
    ' | nsupdate -4 -l"
    system(cmd)
 
    # Generate PTR records for A records, but assumes the arpa zones are preexisting.
    if resource[:type] == 'A'
      fqdn = resource[:record]
      if fqdn[fqdn.length - 1] != '.'
        fqdn += resource[:zone]
      end
      reverse = IPAddr.new(resource[:data]).reverse
      cmd = "echo 'update delete #{reverse} PTR
      update add #{reverse} #{resource[:ttl]} PTR #{fqdn}
      send
      quit
      ' | nsupdate -4 -l"
      system(cmd)
    end

    # Refresh state - might not be necessary? Need to just update state on a per-resource basis
    @property_hash = self.class.parse_records
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end
end
