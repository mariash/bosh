module Bosh::Director
  module ApiNats
    class DynamicDiskController
      include ValidationHelper

      USERNAME = "bosh-agent".freeze

      def initialize(logger, nats_rpc)
        @nats_rpc = nats_rpc
        @logger = logger
      end

      def handle_create_disk_request(reply, payload)
        JobQueue.new.enqueue(
          USERNAME,
          Jobs::CreateDynamicDisk,
          'create dynamic disk',
          [reply, payload]
        )
      rescue => e
        @nats_rpc.send_message(reply, { "error" => e.message })
        raise
      end

      def handle_attach_disk_request(agent_id, reply, payload)
        JobQueue.new.enqueue(
          USERNAME,
          Jobs::AttachDynamicDisk,
          'attach dynamic disk',
          [agent_id, reply, payload]
        )
      rescue => e
        @nats_rpc.send_message(reply, { 'error' => e.message })
        raise
      end

      def handle_provide_disk_request(agent_id, reply, payload)
        deployment = safe_property(payload, "deployment", class: String)
        disk_name = safe_property(payload, "disk_name", class: String)
        disk_pool_name = safe_property(payload, "disk_pool_name", class: String)
        disk_size = safe_property(payload, "disk_size", class: Integer)
        metadata = safe_property(payload, "metadata", class: Hash, optional: true)
        
        JobQueue.new.enqueue(
          USERNAME,
          Jobs::DynamicDisk::ProvideDynamicDisk,
          'provide dynamic disk',
          [agent_id, reply, deployment, disk_name, disk_pool_name, disk_size, metadata]
        )
      rescue => e
        @nats_rpc.send_message(reply, { "error" => e.message })
        raise
      end

      def handle_detach_disk_request(agent_id, reply, payload)
        JobQueue.new.enqueue(
          USERNAME,
          Jobs::DetachDynamicDisk,
          'detach dynamic disk',
          [agent_id, reply, payload]
        )
      rescue => e
        @nats_rpc.send_message(reply, { "error" => e.message })
        raise
      end

      def handle_delete_disk_request(reply, payload)
        JobQueue.new.enqueue(
          USERNAME,
          Jobs::DeleteDynamicDisk,
          'delete dynamic disk',
          [reply, payload]
        )
      rescue => e
        # TODO is this right? Not sure what the best practice is here in rb
        #   Also is there a generic decorator like pattern for this?
        @nats_rpc.send_message(reply, { "error" => e.message })
        raise
      end
    end
  end
end