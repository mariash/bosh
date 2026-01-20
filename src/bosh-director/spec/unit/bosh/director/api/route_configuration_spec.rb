require 'spec_helper'

module Bosh::Director
  describe Api::RouteConfiguration do
    let(:config) { Config.new({}) }
    subject(:route_configuration) { Api::RouteConfiguration.new(config) }
    before { allow(App).to receive_message_chain(:new, :blobstores, :blobstore) }

    it 'creates controllers' do
      expect { route_configuration.controllers }.not_to raise_error
    end

    context 'when dynamic disks are enabled' do
      before { allow(Config).to receive(:dynamic_disks_enabled?).and_return(true) }

      it 'configures dynamic disks controller' do
        expect(route_configuration.controllers).to include('/dynamic_disks')
      end
    end

    context 'when dynamic disks are disabled' do
      before { allow(Config).to receive(:dynamic_disks_enabled?).and_return(false) }

      it 'does not configure dynamic disks controller' do
        expect(route_configuration.controllers).not_to include('/dynamic_disks')
      end
    end
  end
end
