require 'cloud'
require 'common/exec'
require 'json'
require 'tempfile'

require 'smartos/version'

module SmartOS

  ##
  # CPI - Cloud Provider Interface, used for interfacing with various IaaS APIs.
  #
  # Key terms:
  # Stemcell: template used for creating VMs (shouldn't be powered on)
  # VM:       VM created from a stemcell with custom settings (networking and resources)
  # Disk:     volume that can be attached and detached from the VMs,
  #           never attached to more than a single VM at one time
  class Cloud < Bosh::Cloud
    include Bosh::Exec

    ##
    # Cloud initialization
    #
    # @param [Hash] options cloud options
    def initialize(options)
      # persistent disk base path
    end

    ##
    # Creates a stemcell
    #
    # @param [String] image_path path to an opaque blob containing the stemcell image
    # @param [Hash] cloud_properties properties required for creating this template
    #               specific to a CPI
    # @return [String] image uuid
    def create_stemcell(image_path, stemcell_properties)
      uuid = stemcell_properties['uuid']
      sh "imgadm import #{uuid}"
      # http://wiki.smartos.org/display/DOC/Managing+Images#ManagingImages-CreatingaZoneImage
      uuid
    end

    ##
    # Deletes a stemcell
    #
    # @param [String] stemcell_id stemcell uuid from {#create_stemcell}
    # @return [void]
    def delete_stemcell(stemcell_id)
      sh "imgadm destroy #{stemcell_id}"
    end

    ##
    # Creates a VM - creates (and powers on) a VM from a stemcell with the proper resources
    # and on the specified network. When disk locality is present the VM will be placed near
    # the provided disk so it won't have to move when the disk is attached later.
    #
    # Sample networking config:
    #  {"network_a" =>
    #    {
    #      "netmask"          => "255.255.248.0",
    #      "ip"               => "172.30.41.40",
    #      "gateway"          => "172.30.40.1",
    #      "dns"              => ["172.30.22.153", "172.30.22.154"],
    #      "cloud_properties" => {"name" => "VLAN444"}
    #    }
    #  }
    #
    # Sample resource pool config (CPI specific):
    #  {
    #    "ram"  => 512,
    #    "disk" => 512,
    #    "cpu"  => 1
    #  }
    # or similar for EC2:
    #  {"name" => "m1.small"}
    #
    # @param [String] agent_id UUID for the agent that will be used later on by the director
    #                 to locate and talk to the agent
    # @param [String] stemcell stemcell id that was once returned by {#create_stemcell}
    # @param [Hash] resource_pool cloud specific properties describing the resources needed
    #               for this VM
    # @param [Hash] networks list of networks and their settings needed for this VM
    # @param [optional, String, Array] disk_locality disk id(s) if known of the disk(s) that will be
    #                                    attached to this vm
    # @param [optional, Hash] env environment that will be passed to this vm
    # @return [String] opaque id later used by {#configure_networks}, {#attach_disk},
    #                  {#detach_disk}, and {#delete_vm}
    def create_vm(agent_id, stemcell_id, resource_pool,
                  networks, disk_locality = nil, env = nil)

      config = vm_config(stemcell_id, networks.values.first)
      file = config_file(config)

      result = sh "vmadm create -f #{file.to_path}"
      result.output.match(/^Successfully created (.+)$/)[1]
    ensure
      FileUtils.rm_f(file)
    end

    ##
    # Deletes a VM
    #
    # @param [String] vm_id vm id that was once returned by {#create_vm}
    # @return [void]
    def delete_vm(vm_id)
      sh "vmadm delete #{vm_id}"
    end

    ##
    # Reboots a VM
    #
    # @param [String] vm vm id that was once returned by {#create_vm}
    # @param [Optional, Hash] CPI specific options (e.g hard/soft reboot)
    # @return [void]
    def reboot_vm(vm_id)
      sh "vmadm reboot #{vm_id}"
    end

    ##
    # Set metadata for a VM
    #
    # Optional. Implement to provide more information for the IaaS.
    #
    # @param [String] vm vm id that was once returned by {#create_vm}
    # @param [Hash] metadata metadata key/value pairs
    # @return [void]
    def set_vm_metadata(vm, metadata)
      not_implemented(:set_vm_metadata)
      # add attr; set type=string; set name=foo; set value=bar; end; commit
      # remove attr name=...
      # info attr name=...
      # zonecfg -z <uuid> -f <file>

  end

    ##
    # Configures networking an existing VM.
    #
    # @param [String] vm vm id that was once returned by {#create_vm}
    # @param [Hash] networks list of networks and their settings needed for this VM,
    #               same as the networks argument in {#create_vm}
    # @return [void]
    def configure_networks(vm_id, networks)
      not_implemented(:configure_networks)
    end

    ##
    # Creates a disk (possibly lazily) that will be attached later to a VM. When
    # VM locality is specified the disk will be placed near the VM so it won't have to move
    # when it's attached later.
    #
    # @param [Integer] size disk size in MB
    # @param [optional, String] vm_locality vm id if known of the VM that this disk will
    #                           be attached to
    # @return [String] opaque id later used by {#attach_disk}, {#detach_disk}, and {#delete_disk}
    def create_disk(size, vm_locality = nil)
      not_implemented(:create_disk)
      # zfs create
    end

    ##
    # Deletes a disk
    # Will raise an exception if the disk is attached to a VM
    #
    # @param [String] disk disk id that was once returned by {#create_disk}
    # @return [void]
    def delete_disk(disk_id)
      not_implemented(:delete_disk)
      # zfs delete
    end

    ##
    # Attaches a disk
    #
    # @param [String] vm vm id that was once returned by {#create_vm}
    # @param [String] disk disk id that was once returned by {#create_disk}
    # @return [void]
    def attach_disk(vm_id, disk_id)
      not_implemented(:attach_disk)
      # zfs set mountpoint=/zones/<uuid>/root/var/vcap/data zones/ephemeral/<uuid>
    end

    ##
    # Detaches a disk
    #
    # @param [String] vm vm id that was once returned by {#create_vm}
    # @param [String] disk disk id that was once returned by {#create_disk}
    # @return [void]
    def detach_disk(vm_id, disk_id)
      not_implemented(:detach_disk)
      # zfs unmount ?
      # zfs set mountpoint=/zones/<uuid>/root/var/vcap/data zones/ephemeral/<uuid>
    end

    ##
    # Validates the deployment
    # @api not_yet_used
    def validate_deployment(old_manifest, new_manifest)
      not_implemented(:validate_deployment)
    end


    def vm_config(dataset_uuid, network)
      {
          'brand' => "joyent",
          'dataset_uuid' => dataset_uuid,
          'nics' => [
              {
                  'nic_tag' => 'admin',
                  'ip' => network['ip'],
                  'netmask' => network['netmask'],
                  'gateway' => network['gateway']
              }
          ]
      }
    end

    def config_file(config)
      file = Tempfile.new(['vmcfg', '.json'])
      File.open(file, 'w') do |f|
        f.write(JSON.generate(config))
      end
      file
    end

    def get_zone_attr(uuid, attr_name)
      result = sh("zonecfg -z #{uuid} 'info attr name=#{attr_name}'")
      match = result.output.match(/value: (\S+)$/)
      match ? match[1] : nil
    end

    def set_zone_attr(uuid, attr_name, value)
      cmd = "add attr; set type=string; set name=#{attr_name}; set value=#{value}; end; commit"
      sh "zonecfg -z #{uuid} '#{cmd}'"
    end

    def has_zone_attr?(uuid, attr_name)
      !!get_zone_attr(uuid, attr_name)
    end

    private

    def not_implemented(method)
      raise Bosh::Clouds::NotImplemented,
            "`#{method}' is not implemented by #{self.class}"
    end

    def valid_zone?(uuid)
      sh "zoneadm -u #{uuid} list"
    rescue Bosh::Exec::Error
      # raise cloud error
    end

  end
end
