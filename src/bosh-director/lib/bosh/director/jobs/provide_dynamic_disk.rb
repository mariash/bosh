module Bosh::Director
  module Jobs
    class ProvideDynamicDisk < BaseJob

      @queue = :normal

      def self.job_type
        :provide_dynamic_disk
      end

      def initialize(subject, reply, payload)
        @subject = subject
        @reply = reply
        @payload = payload
      end

      def perform
        message = parse_payload
        validate_message(message)

        # subject: director.agent.disk.provide.agent_id
        agent_id = @subject.split('.', 5).last
        raise 'Subject must include agent_id' if agent_id.empty?

        cloud_properties = find_disk_cloud_properties(message['disk_pool_name'])

        cloud = Bosh::Director::CloudFactory.create.get(nil)
        unless cloud.has_disk(message['disk_name'])
          disk_name = cloud.create_disk(message['disk_size'], cloud_properties, nil)
          # TODO: save in database
        end

        if message['metadata'] != nil && cloud.respond_to?(:set_disk_metadata)
          cloud.set_disk_metadata(disk_name, message['metadata'])
        end

        vm_cid = Models::Vm.find(agent_id: agent_id).cid
        disk_hint = cloud.attach_disk(vm_cid, disk_name)

        response = {
          'error' => nil,
          'disk_name' => disk_name,
          'disk_hint' => disk_hint,
        }
        Config.nats_rpc.send_message(@reply, response)

        "attached disk '#{disk_name}' to '#{vm_cid}' in deployment '#{message['deployment']}'"
      rescue => e
        if message.is_a?(Hash) && message.has_key?('reply_to')
          response = {
            'error' => e.message,
          }
          Config.nats_rpc.send_message(message['reply_to'], response)
        end

        raise e
      end

      private

      def find_disk_cloud_properties(disk_pool_name)
        configs = Models::Config.latest_set('cloud')
        raise 'No cloud configs provided' if configs.empty?

        consolidated_configs = Bosh::Director::CloudConfig::CloudConfigsConsolidator.new(configs)
        cloud_config_disk_type = DeploymentPlan::CloudManifestParser.new(logger).parse(consolidated_configs.raw_manifest).disk_type(disk_pool_name)
        raise "Could not find disk pool by name `#{disk_pool_name}`" if cloud_config_disk_type.nil?

        cloud_config_disk_type.cloud_properties
      end

      def parse_payload
        case @payload
        when String
          return JSON.parse(@payload)
        when Hash
          return @payload
        else
          raise "Payload must be a JSON string or hash"
        end
      end

      def validate_message(payload)
        if payload['deployment'].nil? || payload['deployment'].empty?
          raise 'Invalid request: `deployment` must be provided'
        elsif payload['disk_name'].nil? || payload['disk_name'].empty?
          raise 'Invalid request: `disk_name` must be provided'
        elsif payload['disk_size'].nil? || payload['disk_size'] == 0
          raise 'Invalid request: `disk_size` must be provided'
        elsif payload['disk_pool_name'].nil? || payload['disk_pool_name'].empty?
          raise 'Invalid request: `disk_pool_name` must be provided'
        elsif @reply.nil? || @reply.empty?
          raise 'Invalid request: `disk_pool_name` must be provided'
        end
      end
    end
  end
end