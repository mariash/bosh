module Bosh::Director
  module ApiNats
    class Api
      extend ValidationHelper

      USERNAME = "bosh-agent".freeze

      def initialize(logger, nats_rpc)
        @nats_rpc = nats_rpc
        @logger = logger
      end

      def setup_events
        disk_controller = DynamicDiskController.new(@nats_rpc, @logger)

        disk_controller.handlers.map do |key, handler|
          @nats_rpc.nats.subscribe(key) do |payload, reply, subject|
            payload = parse_payload(payload)
            handler.call(reply, subject, payload)
          rescue => e
            @nats_rpc.send_message(reply, { "error" => e.message })
            raise
          end
        end
      end

      private

      def parse_agent_id(subject)
        # subject: director.agent.disk.provide.agent_id
        agent_id = subject.split('.', 5).last
        raise 'Subject must include agent_id' if agent_id.empty?
        return agent_id
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
end