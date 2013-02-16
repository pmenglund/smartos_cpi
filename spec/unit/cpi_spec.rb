require "spec_helper"

describe SmartOS::Cloud::CPI do
  let(:options) { {} }
  let(:cpi) do
    SmartOS::Cloud::Zfs.should_receive(:create_dataset)
    described_class.new(options)
  end

  describe '#create_stemcell' do
    let(:image_path) { '/doesnt/matter' }
    let(:stemcell_properties) do
      { 'uuid' => 'uuid' }
    end

    it 'should create a stemcell' do
      cpi.should_receive(:sh).with('imgadm import uuid')
      # installing image 84cb7edc-3f22-11e2-8a2a-3f2a7b148699
      # 84cb7edc-3f22-11e2-8a2a-3f2a7b148699 successfully installed
      # image 84cb7edc-3f22-11e2-8a2a-3f2a7b148699 successfully imported

      cpi.create_stemcell(image_path, stemcell_properties).should == 'uuid'
    end
  end

  describe '#delete_stemcell' do
    it 'should delete a stemcell' do
      cpi.should_receive(:sh).with('imgadm destroy uuid')

      cpi.delete_stemcell('uuid')
    end
  end

  describe '#create_vm' do
    let(:agent_id) { 'agent-007' }
    let(:stemcell_id) { 'f903258a-480d-408b-bb72-e0514396a465' }
    let(:resource_pool) { {} }
    let(:networks) do
      {
          'network_1' => {
              'ip' => '1.2.3.4',
              'netmask' => '255.255.255.0',
              'gateway' => '1.2.3.1'
          }
      }
    end

    it 'should create a new zone' do
      result = double('result', :output => 'Successfully created f903258a-480d-408b-bb72-e0514396a465')
      cpi.should_receive(:sh).with(%r{^vmadm create -f .+\.json$})
        .and_return(result)

      FileUtils.should_receive(:rm_f)

      cpi.create_vm(agent_id, stemcell_id, resource_pool, networks)
    end
  end

  describe '#delete_vm' do
    it 'should delete a zone' do
      cpi.should_receive(:sh).with('vmadm delete uuid')

      cpi.delete_vm('uuid')
    end
  end

  describe '#reboot_vm' do
    it 'should reboot a zone' do
      cpi.should_receive(:sh).with('vmadm reboot uuid')

      cpi.reboot_vm('uuid')
    end
  end

  describe '#set_vm_metadata' do
    it 'should set metadata' do
      zone = double("zone")
      SmartOS::Cloud::Zone.should_receive(:new).with('uuid').and_return(zone)

      zone.should_receive(:set_attr).with('key1', 'value1')
      zone.should_receive(:set_attr).with('key2', 'value2')
      cpi.set_vm_metadata('uuid', {'key1' => 'value1', 'key2' => 'value2'})
    end
  end
end
