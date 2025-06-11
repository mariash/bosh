module Bosh::Director
  class DynamicDiskManager
    USERNAME = "bosh-agent".freeze

    def initialize(logger)
      @logger = logger
    end

    def setup_events
      Config.nats_rpc.nats.subscribe('director.agent.disk.provide.*') do |payload, reply, subject|
        @logger.info("received payload: #{payload}")
        handle_provide_disk_request(subject, reply, payload)
      end

      Config.nats_rpc.nats.subscribe('director.agent.disk.detach.*') do |payload, _reply, _subject|
        handle_detach_disk_request(payload)
      end

      Config.nats_rpc.nats.subscribe('director.agent.disk.delete.*') do |payload, _reply, _subject|
        handle_delete_disk_request(payload)
      end
    end

    private

    def handle_provide_disk_request(subject, reply, payload)
      JobQueue.new.enqueue(
          USERNAME,
          Jobs::ProvideDynamicDisk,
          'provide dynamic disk',
          [subject, reply, payload]
        )
    end

    def handle_detach_disk_request(payload)
    end

    def handle_delete_disk_request(payload)
    end

  end
end