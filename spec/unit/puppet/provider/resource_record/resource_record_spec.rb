# frozen_string_literal: true

require 'spec_helper'

require 'puppet/provider/resource_record/resource_record'
describe Puppet::Type.type(:resource_record).provider(:ruby) do
  
  let(:record) { 'test.example.com.' }
  let(:zone) { 'example.com.' }
  let(:type) { 'A' }
  let(:data) { '127.0.0.1' }
  let(:common_params) do 
    { 
      title: 'test.example.com._A01' 
    } 
  end

  describe '.instances' do
    before do
      allow(Puppet::Type.type(:resource_record).provider(:ruby).to receive(:instances).and_return([provider])
    end
    it 'processes resources' do
      expect(context).to receive(:debug).with('Returning pre-canned example data')
      expect(provider.get(context)).to eq [
        {
          name: 'foo',
          ensure: 'present',
        },
        {
          name: 'bar',
          ensure: 'present',
        },
      ]
    end
  end

  describe 'create(context, name, should)' do
    it 'creates the resource' do
      expect(context).to receive(:notice).with(%r{\ACreating 'a'})

      provider.create(context, 'a', name: 'a', ensure: 'present')
    end
  end

  describe 'update(context, name, should)' do
    it 'updates the resource' do
      expect(context).to receive(:notice).with(%r{\AUpdating 'foo'})

      provider.update(context, 'foo', name: 'foo', ensure: 'present')
    end
  end

  describe 'delete(context, name)' do
    it 'deletes the resource' do
      expect(context).to receive(:notice).with(%r{\ADeleting 'foo'})

      provider.delete(context, 'foo')
    end
  end

  describe 'canonicalize(_context, resources)' do
    it 'upcases/downcases resource attributes' do
      expect(provider.canonicalize(context,
        [{
          ensure: 'present',
          record: 'wWw',
          zone: 'EXAMPLE.com.',
          type: 'aaaa',
          data: '2001:db8::1',
        }])).to eq(
          [{
            ensure: 'present',
            record: 'www',
            zone: 'example.com.',
            type: 'AAAA',
            data: '2001:db8::1',
          }],
        )
    end
  end
end
