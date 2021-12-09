Puppet::Type.newtype(:resource_record) do
  @doc = <<-DOC,
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
         DOC
  ensurable do
    defaultvalues
    defaultto :present
  end

  def self.title_patterns
    # Cheating a bit with forcing a single title value. 
    [
      #foo.example.com._AAAA00
      [
        %r{(.*)(?: |_)+}, 
        [
          [:record],
        ],
      ],
       #foo.example.com. example.com. A 127.0.0.1
      [
        %r{^(.*?\.) ([^ ]*\.) +(\w+) (.*)$}, 
        [
          [:record],
          [:zone],
          [:type],
          [:data],
        ],
      ],
        #foo.example.com. example.com. A
      [
        %r{^(.*?\.) ([^ ]*\.) +(\w+)$}, 
        [
          [:record],
          [:zone],
          [:type],
          [:data],
        ],
      ],
    ]
  end
  
  validate do
    raise ArgumentError, 'record is a required parameter.' if self[:record].nil?
    raise ArgumentError, 'zone is a required parameter.' if self[:zone].nil?
    raise ArgumentError, 'type is a required parameter.' if self[:type].nil?
    raise ArgumentError, 'data is a required parameter.' if self[:data].nil?
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

 
  def name
    "#{self[:record]} #{self[:zone]} #{self[:type]} #{self[:data]}"
  end

end
