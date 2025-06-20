require 'spec_helper'

# module Bosh::Director
#   describe ApiNats::DynamicDiskController do
    # subject(:controller) { DynamicDiskController.new(per_spec_logger, nats_rpc) }
    # let(:nats_rpc) { instance_double('Bosh::Director::NatsRpc') }
    # let(:job_queue) { instance_double('Bosh::Director::JobQueue') }

    # describe 'handle_provide_disk_request' do
    #   let(:agent_id) { 'fake_agent_id' }
    #   let(:reply) { 'inbox.fake' }
    #   let(:deployment) { 'fake_deployment_name' }
    #   let(:disk_pool_name) { 'fake_disk_pool_name' }
    #   let(:disk_name) { 'fake_disk_name' }
    #   let(:disk_size) { 1000 }
    #   let(:payload) { {
    #     deployment: deployment,
    #     disk_pool_name: disk_pool_name,
    #     disk_name: disk_name,
    #     disk_size: disk_size,
    #   } }


    #   it 'schedules a job' do
    #     expect(controller.handle_provide_disk_request(agent_id, reply, payload)).to eq(nil)
    #     expect(job_queue).to receive_message_chain(:new, :enqueue)
    #   end

    #   context 'payload is invalid' do
    #     it '' do
    #       expect(instance_lookup.by_id(instance.id)).to eq instance
    #       expect(nats_rpc).to have_received(:fake)
    #     end
    #   end
    #   #
    #   # context 'no instance exists for id' do
    #   #   it 'raises' do
    #   #     expect {
    #   #       instance_lookup.by_id(999999)
    #   #     }.to raise_error(InstanceNotFound, "Instance 999999 doesn't exist")
    #   #   end
    #   # end
    # end

    # describe '.by_attributes' do
    #   it 'finds instance based on attribute vector' do
    #     expect(instance_lookup.by_attributes(deployment, job_name, job_index)).to eq(instance)
    #   end
    #
    #   context 'no instance exists for attribute vector' do
    #     it 'raises' do
    #       expect {
    #         instance_lookup.by_attributes(deployment, job_name, '7')
    #       }.to raise_error(InstanceNotFound, "'#{deployment.name}/#{job_name}/7' doesn't exist")
    #     end
    #   end
    #
    #   context 'when attributes are are empty strings' do
    #     let(:cleansed_filter_attributes) do
    #       { deployment: anything, job: '', index: nil }
    #     end
    #
    #     it 'converts the empty string to nil so that postgres will not raise on trying to convert an empty string to integer' do
    #       expect(Models::Instance).to receive(:find).with(cleansed_filter_attributes).and_return(instance)
    #       expect { instance_lookup.by_attributes(deployment, '', '') }.to_not raise_error
    #     end
    #   end
    # end
    #
    # describe '.by_filter' do
    #   it 'finds only instances that match sql filter' do
    #     expect(instance_lookup.by_filter(id: instance.id).all).to eq([instance])
    #   end
    #
    #   context 'no instances exist for sql filter' do
    #     it 'raises' do
    #       expect {
    #         instance_lookup.by_filter(id: 987654321)
    #       }.to raise_error(InstanceNotFound, "No instances matched {:id=>987654321}")
    #     end
    #   end
    # end
    #
    # describe '.find_all' do
    #   it 'pulls all instances' do
    #     expect(instance_lookup.find_all).to eq [instance, another_instance]
    #   end
    # end
    #
    # describe '#by_deployment' do
    #   context 'when multiple deployments have instances' do
    #     let!(:deployment_one) { FactoryBot.create(:models_deployment) }
    #     let!(:instance_one) { FactoryBot.create(:models_instance, deployment: deployment_one) }
    #     let!(:deployment_two) { FactoryBot.create(:models_deployment) }
    #     let!(:instance_two) { FactoryBot.create(:models_instance, deployment: deployment_two) }
    #
    #     it 'finds only the instance from given deployment' do
    #       expect(subject.by_deployment(deployment_one)).to eq [instance_one]
    #       expect(subject.by_deployment(deployment_two)).to eq [instance_two]
    #     end
    #   end
    #
    #   context 'when deployment has no instances' do
    #     it 'finds no instances' do
    #       deployment = FactoryBot.create(:models_deployment, name: 'deployment_without_instance')
    #
    #       expect(subject.by_deployment(deployment)).to eq []
    #     end
    #   end
    # end
    #
    # describe '#by_vm_cid' do
    #   context 'when vm with cid is active vm for instance' do
    #     before do
    #       vm = FactoryBot.create(:models_vm, cid: 'vm-cid', instance: instance, active: true)
    #       vm.save
    #     end
    #
    #     it 'finds the instance with the vm' do
    #       expect(subject.by_vm_cid('vm-cid')).to eq([instance])
    #     end
    #   end
    #
    #   context 'when the vm is not found as active on instance' do
    #     before do
    #       vm = FactoryBot.create(:models_vm, cid: 'vm-cid', instance: instance, active: false)
    #       vm.save
    #     end
    #
    #     it 'finds no instances' do
    #       expect {
    #         instance_lookup.by_vm_cid('vm-cid')
    #       }.to raise_error(InstanceNotFound, "No instances matched vm cid 'vm-cid'")
    #     end
    #   end
    # end
#   end
# end
