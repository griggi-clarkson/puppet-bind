
Puppet::Type.newtype(:resource_record) do
  @doc = <<~EOS,
          @summary a DNS resource record type
          @example AAAA record in the example.com. zone
            resource_record { 'foo.example.com._AAAA00':
              ensure => 'present',
              type   => 'AAAA',
              data   => '2001:db8::1',
            }

          This type provides Puppet with the capabilities to manage DNS resource records.

          **Autorequires**: If Puppet is managing the zone that this resource record belongs to,
          the resource record will autorequire the zone.
       EOS
  ensurable do
    defaultvalues
    defaultto :present
  end
  newproperty(:record) do
    desc 'The name of the resource record, also known as the owner or label.'
    isnamevar
    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, _("Record must be a String not %{klass}") % { klass: value.class }
      end
    end
  end
  newproperty(:zone) do
    desc 'The zone the resource record belongs to.'
    isnamevar
    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, _("Zone must be a String not %{klass}") % { klass: value.class }
      end
    end
  end
  newproperty(:type) do
    desc 'The type of the resource record.'
    isnamevar
    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, _("Type must be a String not %{klass}") % { klass: value.class }
      end
    end
  end
  newproperty(:data) do
    desc 'The data for the resource record.'
    isnamevar
    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, _("Data must be a String not %{klass}") % { klass: value.class }
      end
    end
    munge do |value|
      value.tr('\"', '')
    end
  end
  newproperty(:ttl) do
    desc 'The TTL for the resource record.'
  end

  def self.title_patterns
    # Cheating a bit with forcing a single title value. 
    [[%r{(.*)(?: |_)+}m, [[:record]]]]
  end
  
  def self.name
    "#{self[:record]} #{self[:zone]} #{self[:type]} #{self[:data]}"
  end

  validate do
    message = ''
    if original_parameters[:record].nil?
      message += 'record is a required parameter. '
    end
    if original_parameters[:zone].nil?
      message += 'zone is a required parameter. '
    end
    if original_parameters[:type].nil?
      message += 'type is a required parameter. '
    end
    if original_parameters[:data].nil?
      message += 'data is a required parameter. '
    end
    if message != ''
      raise(Puppet::Error, message)
    end
  end
end

    #  desc: 'full name, space, zone (explicitly defined), space, type, space, data',
    #  pattern: %r{^(?<record>.*?\.) (?<zone>[^ ]*\.) +(?<type>\w+) (?<data>.*)$},
    #  desc: 'full name, space, zone (explicitly defined), space, type',
    #  pattern: %r{^(?<record>.*?\.) (?<zone>[^ ]*\.) +(?<type>\w+)$},
    #  desc: 'name and zone (everything after the first dot)',
    #  pattern: %r{^(?<record>.*?[^.])\.(?<zone>.*\.)$},
    #  desc: 'short name (not FQDN), space, type',
    #  pattern: %r{^(?<record>.*[^ ]) +(?<type>.*)$},
    #  desc: 'name only',
    #  pattern: %r{^(?<record>.*)$},
 
