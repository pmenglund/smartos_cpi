require 'spec_helper'

describe SmartOS::Cloud::Zfs do
  let(:base) { 'zones/presistent' }
  let(:zfs) { described_class.new(base) }

  describe '#create' do
    it 'should create a file system' do
      uuid = '1234'
      cmd = "zfs create -o reservation=1024 -o quota=1024 #{zfs.base}/#{uuid}"

      zfs.should_receive(:uuid).and_return(uuid)
      zfs.should_receive(:sh).with(cmd)

      zfs.create('1024').should == uuid
    end
  end

  describe '#destroy' do
    it 'should create a file system' do
      uuid = '1234'

      zfs.should_receive(:sh).with("zfs destroy #{zfs.base}/#{uuid}")

      zfs.destroy(uuid)
    end
  end

  describe '#unmount' do
    it 'should unmount a file system' do
      zone_id = '1234'
      disk_id = '5678'

      cmd = "zfs unmount #{zfs.base}/#{disk_id}"

      zfs.should_receive(:sh).with(cmd)

      zfs.unmount(zone_id, disk_id)
    end
  end

  describe '#mount' do
    it 'should mount a file system' do
      zone_id = '1234'
      disk_id = '5678'
      path = described_class::MOUNT_PATH % zone_id
      cmd = "zfs set -o mountpoint=#{path} #{zfs.base}/#{disk_id}"

      Dir.should_receive(:exist?).with(path).and_return(false)
      FileUtils.should_receive(:mkdir_p).with(path)
      zfs.should_receive(:sh).with(cmd)
      zfs.should_receive(:sh).with("zfs mount #{zfs.base}/#{disk_id}")

      zfs.mount(zone_id, disk_id)
    end
  end

  describe '.create_dataset' do
    it 'should create the dataset if it is absent' do
      path = 'zones/persistent'

      result = double('result', :success? => false)
      described_class.should_receive(:sh).with("zfs list #{path}", :on_error => :return).and_return(result)
      described_class.should_receive(:sh).with("zfs create #{path}")

      described_class.create_dataset(path)
    end

    it 'should not create the dataset if it is present' do
      path = 'zones/persistent'

      result = double('result', :success? => true)

      described_class.should_receive(:sh).with("zfs list #{path}", :on_error => :return).and_return(result)
      described_class.should_not_receive(:sh).with("zfs create #{path}")

      described_class.create_dataset(path)

    end
  end
end
