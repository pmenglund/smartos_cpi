module SmartOS::Cloud
  class Zfs
    include Bosh::Exec

    attr_reader :base

    MOUNT_PATH = "/zones/%s/root/var/vcap/store"

    def initialize(base)
      @base = base
    end

    # disk locality isn't implemented, as the CPI only works on a single system
    def create(size)
      disk_id = uuid
      sh "zfs create -o reservation=1024 -o quota=1024 #{base}/#{disk_id}"
      disk_id
    end

    def destroy(disk_id)
      sh "zfs destroy #{base}/#{disk_id}"
    end

    def mount(zone_id, disk_id)
      path = MOUNT_PATH % zone_id
      FileUtils.mkdir_p(path) unless Dir.exist?(path)
      sh "zfs set -o mountpoint=#{path} #{base}/#{disk_id}"
      sh "zfs mount #{base}/#{disk_id}"
    end

    def unmount(zone_id, disk_id)
      sh "zfs unmount #{base}/#{disk_id}"
    end

    def uuid
      UUIDTools::UUID.random_create
    end
  end
end
