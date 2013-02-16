module SmartOS::Cloud
  class Zone
    include Bosh::Exec

    attr_reader :uuid

    def initialize(uuid)
      @uuid = uuid
    end

    def get_attr(attr_name)
      result = sh("zonecfg -z #{uuid} 'info attr name=#{attr_name}'")
      match = result.output.match(/value: (\S+)$/)
      match ? match[1] : nil
    end

    def set_attr(attr_name, value)
      cmd = "add attr; set type=string; set name=#{attr_name}; set value=#{value}; end; commit"
      sh "zonecfg -z #{uuid} '#{cmd}'"
    end

    def has_attr?(attr_name)
      !!get_attr(attr_name)
    end

    def valid?
      Zone.zones.include?(uuid)
    end

    def self.zones
      result = sh 'zoneadm list'
      result.output.split("\n")
    end

  end
end
