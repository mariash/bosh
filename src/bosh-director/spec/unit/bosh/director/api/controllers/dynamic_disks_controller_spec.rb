require 'spec_helper'
require 'rack/test'

module Bosh::Director
  module Api
    describe Controllers::DynamicDisksController do
      include Rack::Test::Methods

      subject(:app) { linted_rack_app(described_class.new(config)) }
      let(:config) do
        config = Config.load_hash(SpecHelper.director_config_hash)
        identity_provider = Support::TestIdentityProvider.new(config.get_uuid_provider)
        allow(config).to receive(:identity_provider).and_return(identity_provider)
        config
      end
      before { App.new(config) }

      let(:instance_id) { 'fake-instance-id' }
      let(:disk_pool_name) { 'fake_disk_pool_name' }
      let(:disk_name) { 'fake_disk_name' }
      let(:disk_size) { 1000 }
      let(:metadata) { { 'some-key' => 'some-value' } }

      describe 'POST', '/provide' do
        let(:content) do
          JSON.generate({
                      'instance_id' => instance_id,
                      'disk_pool_name' => disk_pool_name,
                      'disk_name' => disk_name,
                      'disk_size' => disk_size,
                      'metadata' => metadata
                    })
        end

        let(:instance) { FactoryBot.create(:models_instance) }
        let!(:vm) { FactoryBot.create(:models_vm, instance: instance, active: true) }

        context 'when user is reader' do
          before { basic_authorize('reader', 'reader') }

          it 'forbids access' do
            expect(post('/provide', content, {'CONTENT_TYPE' => 'application/json'}).status).to eq(401)
          end
        end

        context 'user has admin permissions' do
          before { authorize 'admin', 'admin' }

          it 'enqueues a ProvideDynamicDisk task' do
            expect_any_instance_of(Bosh::Director::JobQueue).to receive(:enqueue).with(
              'admin',
              Jobs::DynamicDisks::ProvideDynamicDisk,
              'provide dynamic disk',
              [instance_id, disk_name, disk_pool_name, disk_size, metadata],
            ).and_call_original

            post '/provide', content, { 'CONTENT_TYPE' => 'application/json' }

            expect_redirect_to_queued_task(last_response)
          end

          context 'content is invalid' do
            context 'disk_pool_name is nil' do
              let(:disk_pool_name) { nil }

              it 'raises an error' do
                post '/provide', content, { 'CONTENT_TYPE' => 'application/json' }

                expect(last_response.status).to eq(400)
                expect(JSON.parse(last_response.body)).to eq(
                                                            'code' => 40000,
                                                            'description' => "Property 'disk_pool_name' value (nil) did not match the required type 'String'",
                                                          )
              end
            end

            context 'disk_pool_name is empty' do
              let(:disk_pool_name) { "" }

              it 'raises an error' do
                post '/provide', content, { 'CONTENT_TYPE' => 'application/json' }

                expect(last_response.status).to eq(400)
                expect(JSON.parse(last_response.body)).to eq(
                                                            'code' => 40002,
                                                            'description' => "'disk_pool_name' length (0) should be greater than 1",
                                                            )
              end
            end

            context 'disk_name is nil' do
              let(:disk_name) { nil }

              it 'raises an error' do
                post '/provide', content, { 'CONTENT_TYPE' => 'application/json' }

                expect(last_response.status).to eq(400)
                expect(JSON.parse(last_response.body)).to eq(
                                                            'code' => 40000,
                                                            'description' => "Property 'disk_name' value (nil) did not match the required type 'String'",
                                                            )
              end
            end

            context 'disk_name is empty' do
              let(:disk_name) { "" }

              it 'raises an error' do
                post '/provide', content, { 'CONTENT_TYPE' => 'application/json' }

                expect(last_response.status).to eq(400)
                expect(JSON.parse(last_response.body)).to eq(
                                                            'code' => 40002,
                                                            'description' => "'disk_name' length (0) should be greater than 1",
                                                          )
              end
            end

            context 'disk_size is empty' do
              let(:disk_size) { nil }

              it 'raises an error' do
                post '/provide', content, { 'CONTENT_TYPE' => 'application/json' }

                expect(last_response.status).to eq(400)
                expect(JSON.parse(last_response.body)).to eq(
                                                            'code' => 40000,
                                                            'description' => "Property 'disk_size' value (nil) did not match the required type 'Integer'",
                                                            )
              end
            end

            context 'disk_size is 0' do
              let(:disk_size) { 0 }

              it 'raises an error' do
                post '/provide', content, { 'CONTENT_TYPE' => 'application/json' }

                expect(last_response.status).to eq(400)
                expect(JSON.parse(last_response.body)).to eq(
                                                            'code' => 40002,
                                                            'description' => "'disk_size' value (0) should be greater than 1",
                                                            )
              end
            end
          end
        end
      end

      # describe 'handle_detach_disk_request' do
      #   let(:payload) do
      #     {
      #       'disk_name' => disk_name,
      #     }.compact
      #   end
      #
      #   it 'enqueues a DetachDynamicDisk task' do
      #     expect(job_queue).to receive(:enqueue).with(
      #       'bosh-agent',
      #       Jobs::DynamicDisks::DetachDynamicDisk,
      #       'detach dynamic disk',
      #       [reply, disk_name],
      #     ).and_return(task)
      #
      #     controller.handle_detach_disk_request(agent_id, reply, payload)
      #   end
      #
      #   context 'payload is invalid' do
      #     context 'disk_name is nil' do
      #       let(:disk_name) { nil }
      #
      #       it 'raises an error' do
      #         expect(nats_rpc).to receive(:send_message).with(reply, hash_including({ 'error' => a_string_matching("Required property 'disk_name'") }))
      #         expect {
      #           controller.handle_detach_disk_request(agent_id, reply, payload)
      #         }.to raise_error(ValidationMissingField)
      #       end
      #     end
      #
      #     context 'disk_name is empty' do
      #       let(:disk_name) { "" }
      #
      #       it 'raises an error' do
      #         expect(nats_rpc).to receive(:send_message).with(reply, hash_including({ 'error' => a_string_matching("'disk_name' length") }))
      #         expect {
      #           controller.handle_detach_disk_request(agent_id, reply, payload)
      #         }.to raise_error(ValidationViolatedMin)
      #       end
      #     end
      #   end
      # end
      #
      # describe 'handle_delete_disk_request' do
      #   let(:payload) do
      #     {
      #       'disk_name' => disk_name,
      #     }.compact
      #   end
      #
      #   it 'enqueues a DeleteDynamicDisk task' do
      #     expect(job_queue).to receive(:enqueue).with(
      #       'bosh-agent',
      #       Jobs::DynamicDisks::DeleteDynamicDisk,
      #       'delete dynamic disk',
      #       [reply, disk_name],
      #     ).and_return(task)
      #
      #     controller.handle_delete_disk_request(reply, payload)
      #   end
      #
      #   context 'payload is invalid' do
      #     context 'disk_name is nil' do
      #       let(:disk_name) { nil }
      #
      #       it 'raises an error' do
      #         expect(nats_rpc).to receive(:send_message).with(reply, hash_including({ 'error' => a_string_matching("Required property 'disk_name'") }))
      #         expect {
      #           controller.handle_delete_disk_request(reply, payload)
      #         }.to raise_error(ValidationMissingField)
      #       end
      #     end
      #
      #     context 'disk_name is empty' do
      #       let(:disk_name) { "" }
      #
      #       it 'raises an error' do
      #         expect(nats_rpc).to receive(:send_message).with(reply, hash_including({ 'error' => a_string_matching("'disk_name' length") }))
      #         expect {
      #           controller.handle_delete_disk_request(reply, payload)
      #         }.to raise_error(ValidationViolatedMin)
      #       end
      #     end
      #   end
      # end
    end
  end
end