#!/usr/bin/env ruby -S rspec

require 'spec_helper'

describe Puppet::Type.type(:network_route) do
  before do
    provider_class = stub 'provider class', name: 'fake', suitable?: true, supports_parameter?: true
    provider_class.stubs(:new)

    Puppet::Type.type(:network_route).stubs(:defaultprovider).returns provider_class
    Puppet::Type.type(:network_route).stubs(:provider).returns provider_class
  end

  describe 'when validating the attribute' do
    describe :name do
      it { expect(Puppet::Type.type(:network_route).attrtype(:name)).to eq(:param) }
    end

    [:ensure, :network, :netmask, :gateway, :interface, :options].each do |property|
      describe property do
        it { expect(Puppet::Type.type(:network_route).attrtype(property)).to eq(:property) }
      end
    end

    it 'use the name parameter as the namevar' do
      expect(Puppet::Type.type(:network_route).key_attributes).to eq([:name])
    end

    describe 'ensure' do
      it 'should be an ensurable value' do
        expect(Puppet::Type.type(:network_route).propertybyname(:ensure).ancestors).to be_include(Puppet::Property::Ensure)
      end
    end
  end

  describe 'when validating the attribute value' do
    describe 'network' do
      it 'should validate the network as an IP address' do
        expect do
          Puppet::Type.type(:network_route).new(name: '192.168.1.0/24', network: 'not an ip address', netmask: '255.255.255.0', gateway: '23.23.23.42', interface: 'eth0')
        end.to raise_error
      end
    end

    describe 'netmask' do
      it 'should fail if an invalid netmask is used' do
        expect do
          Puppet::Type.type(:network_route).new(name: '192.168.1.0/24', network: '192.168.1.0', netmask: 'This is clearly not a netmask', gateway: '23.23.23.42', interface: 'eth0')
        end.to raise_error
      end

      it 'should convert netmasks of the CIDR form' do
        r = Puppet::Type.type(:network_route).new(name: '192.168.1.0/24', network: '192.168.1.0', netmask: '24', gateway: '23.23.23.42', interface: 'eth0')
        expect(r[:netmask]).to eq('255.255.255.0')
      end

      it 'should convert netmasks of the expanded netmask form' do
        r = Puppet::Type.type(:network_route).new(name: '192.168.1.0/24', network: '192.168.1.0', netmask: '255.255.128.0', gateway: '23.23.23.42', interface: 'eth0')
        expect(r[:netmask]).to eq('255.255.128.0')
      end
    end

    describe 'gateway' do
      it 'should validate as an IP address' do
        expect do
          Puppet::Type.type(:network_route).new(name: '192.168.1.0/24', network: '192.168.1.0', netmask: '255.255.255.0', gateway: 'not an ip address', interface: 'eth0')
        end.to raise_error
      end
    end
  end
end
