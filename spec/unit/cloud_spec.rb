require "spec_helper"

describe SmartOS::Cloud do
  let(:options) { {} }
  let(:cpi) { described_class.new(options) }

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

    let(:existing_result) { double('result', :output => "attr:\n	name: foo\n	type: string\n	value: bar") }
    let(:missing_result) { double('result', :output => 'No such attr resource.') }

    describe '#get_zone_attr' do
      it 'should return the attr when it is present' do
        cmd = 'info attr name=name'
        cpi.should_receive(:sh).with("zonecfg -z uuid '#{cmd}'").and_return(existing_result)

        cpi.get_zone_attr('uuid', 'name').should == 'bar'
      end

      it 'should return nil when the attr is absent' do
        cmd = 'info attr name=name'
        cpi.should_receive(:sh).with("zonecfg -z uuid '#{cmd}'").and_return(missing_result)

        cpi.get_zone_attr('uuid', 'name').should be_nil
      end
    end

    describe '#set_zone_attr' do
      it 'should set an attr' do
        cmd = 'add attr; set type=string; set name=name; set value=value; end; commit'
        cpi.should_receive(:sh).with("zonecfg -z uuid '#{cmd}'")

        cpi.set_zone_attr('uuid', 'name', 'value')
      end
    end

    describe '#has_zone_attr?' do
      it 'should return true when the attr is present' do
        cpi.should_receive(:get_zone_attr).with('uuid', 'attr_name').and_return('foo')

        cpi.has_zone_attr?('uuid', 'attr_name').should be_true
      end

      it 'should return false when the attr is absent' do
        cpi.should_receive(:get_zone_attr).with('uuid', 'attr_name').and_return(nil)

        cpi.has_zone_attr?('uuid', 'attr_name').should be_false
      end
    end

  end
end
