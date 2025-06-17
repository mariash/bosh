module Bosh::Director
  class DynamicDiskManager
    USERNAME = "bosh-agent".freeze

    def initialize(logger)
      @logger = logger
    end

    def setup_events
      Config.nats_rpc.nats.subscribe('director.agent.disk.create.*') do |payload, reply, subject|
        handle_create_disk_request(subject, reply, payload)
      end

      Config.nats_rpc.nats.subscribe('director.agent.disk.attach.*') do |payload, reply, subject|
        handle_attach_disk_request(subject, reply, payload)
      end

      Config.nats_rpc.nats.subscribe('director.agent.disk.provide.*') do |payload, reply, subject|
        # TODO log everwhere or nowhere
        @logger.info("received payload: #{payload}")
        handle_provide_disk_request(subject, reply, payload)
      end

      Config.nats_rpc.nats.subscribe('director.agent.disk.detach.*') do |payload, _reply, _subject|
        handle_provide_disk_request(subject, reply, payload)
      end

      Config.nats_rpc.nats.subscribe('director.agent.disk.delete.*') do |payload, _reply, _subject|
        handle_provide_disk_request(subject, reply, payload)
      end
    end

    private

    def handle_create_disk_request(subject, reply, payload)
      payload = parse_payload(payload)
      JobQueue.new.enqueue(
        USERNAME,
        Jobs::CreateDynamicDisk,
        'create dynamic disk',
        [subject, reply, payload]
      )
    rescue => e
      Config.nats_rpc.send_message(reply, {"error" => e.message})
      raise
    end

    def handle_attach_disk_request(subject, reply, payload)
      payload = parse_payload(payload)
      JobQueue.new.enqueue(
        USERNAME,
        Jobs::AttachDynamicDisk,
        'attach dynamic disk',
        [subject, reply, payload]
      )
    rescue => e
      Config.nats_rpc.send_message(reply, {"error" => e.message})
      raise
    end

    def handle_provide_disk_request(subject, reply, payload)
      payload = parse_payload(payload)
      JobQueue.new.enqueue(
          USERNAME,
          Jobs::ProvideDynamicDisk,
          'provide dynamic disk',
          [subject, reply, payload]
        )
    rescue => e
      Config.nats_rpc.send_message(reply, {"error" => e.message})
      raise
    end

    def handle_detach_disk_request(subject, reply, payload)
      payload = parse_payload(payload)
      JobQueue.new.enqueue(
        USERNAME,
        Jobs::DetachDynamicDisk,
        'detach dynamic disk',
        [subject, reply, payload]
      )
    rescue => e
      Config.nats_rpc.send_message(reply, {"error" => e.message})
      raise
    end

    def handle_delete_disk_request(subject, reply, payload)
      payload = parse_payload(payload)
      JobQueue.new.enqueue(
        USERNAME,
        Jobs::DeleteDynamicDisk,
        'delete dynamic disk',
        [subject, reply, payload]
      )
    rescue => e
      # TODO is this right? Not sure what the best practice is here in rb
      #   Also is there a generic decorator like pattern for this?
      Config.nats_rpc.send_message(reply, {"error" => e.message})
      raise
    end

    def parse_payload(payload)
      case payload
      when String
        return JSON.parse(payload)
      when Hash
        return payload
      else
        raise "Payload must be a JSON string or hash"
      end
    end
  end
end