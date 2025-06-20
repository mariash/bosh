module Bosh::Director
  module Jobs
    module DynamicDisk
      class ProvideDynamicDisk < BaseJob
        @queue = :normal

        def self.job_type
          :provide_dynamic_disk
        end

        def initialize(nats_rpc, agent_id, reply, payload)
          super()
          @nats_rpc = nats_rpc
          @agent_id = agent_id
          @reply = reply

          @deployment = payload['deployment']
          @disk_pool_name = payload['disk_pool_name']
          @disk_name = payload['disk_name']
          @disk_size = payload['disk_size']
          @metadata = payload['metadata']
        end

        def perform
          vm = Models::Vm.find(agent_id: @agent_id)
          cloud_properties = find_disk_cloud_properties(vm.instance, @disk_pool_name)

          cloud = Bosh::Director::CloudFactory.create.get(vm.cpi)
          unless cloud.has_disk(@disk_name)
            disk_name = cloud.create_disk(disk_size, cloud_properties, vm_cid)
            # TODO: save in database
          end

          if @metadata != nil && cloud.respond_to?(:set_disk_metadata)
            # TODO implement this
            # metadata_updater_cloud = cloud_factory.get(@disk.cpi)
            # MetadataUpdater.build.update_dynamic_disk_metadata(metadata_updater_cloud, @disk, @tags)
            cloud.set_disk_metadata(disk_name, @metadata)
          end

          disk_hint = cloud.attach_disk(vm_cid, disk_name)

          response = {
            'error' => nil,
            'disk_name' => disk_name,
            'disk_hint' => disk_hint,
          }
          @nats_rpc.send_message(@reply, response)

          "attached disk '#{disk_name}' to '#{vm_cid}' in deployment '#{@deployment}'"
        rescue => e
          @nats_rpc.send_message(@reply, { 'error' => e.message })
          raise e
        end

        private

        def find_disk_cloud_properties(vm, disk_pool_name)
          teams = vm.instance.deployment.teams
          configs = Models::Config.latest_set_for_teams('cloud', *teams)
          raise 'No cloud configs provided' if configs.empty?

          consolidated_configs = Bosh::Director::CloudConfig::CloudConfigsConsolidator.new(configs)
          cloud_config_disk_type = DeploymentPlan::CloudManifestParser.new(logger).parse(consolidated_configs.raw_manifest).disk_type(disk_pool_name)
          raise "Could not find disk pool by name `#{disk_pool_name}`" if cloud_config_disk_type.nil?

          cloud_config_disk_type.cloud_properties
        end
      end
    end
  end
end