require 'spec_helper'

describe SmartOS::Cloud::Zone do
  let(:zone) { described_class.new('uuid') }
  let(:existing_result) { double('result', :output => "attr:\n	name: foo\n	type: string\n	value: bar") }
  let(:missing_result) { double('result', :output => 'No such attr resource.') }

  describe '#get_attr' do
    it 'should return the attr when it is present' do
      cmd = 'info attr name=name'
      zone.should_receive(:sh).with("zonecfg -z uuid '#{cmd}'").and_return(existing_result)

      zone.get_attr('name').should == 'bar'
    end

    it 'should return nil when the attr is absent' do
      cmd = 'info attr name=name'
      zone.should_receive(:sh).with("zonecfg -z uuid '#{cmd}'").and_return(missing_result)

      zone.get_attr('name').should be_nil
    end
  end

  describe '#set_attr' do
    it 'should set an attr' do
      cmd = 'add attr; set type=string; set name=name; set value=value; end; commit'
      zone.should_receive(:sh).with("zonecfg -z uuid '#{cmd}'")

      zone.set_attr('name', 'value')
    end
  end

  describe '#has_attr?' do
    it 'should return true when the attr is present' do
      zone.should_receive(:get_attr).with('attr_name').and_return('foo')

      zone.has_attr?('attr_name').should be_true
    end

    it 'should return false when the attr is absent' do
      zone.should_receive(:get_attr).with('attr_name').and_return(nil)

      zone.has_attr?('attr_name').should be_false
    end
  end

  describe '#valid?' do
    it 'should return true when the uuid is valid' do
      result = double("result", :output => "global\nuuid\nuuid2")
      SmartOS::Cloud::Zone.should_receive(:sh).with('zoneadm list').and_return(result)

      zone.valid?.should be_true
    end

    it 'should return false when the uuid is invalid' do
      result = double("result", :output => "global\nuuid1\nuuid2")
      SmartOS::Cloud::Zone.should_receive(:sh).with('zoneadm list').and_return(result)

      zone.valid?.should be_false
    end
  end

  describe '#zones' do
    it 'should return the zones as an array' do
      result = double("result", :output => "global\nuuid1\nuuid2")
      SmartOS::Cloud::Zone.should_receive(:sh).with('zoneadm list').and_return(result)

      SmartOS::Cloud::Zone.zones.should == %w[global uuid1 uuid2]
    end
  end
end
