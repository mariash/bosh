module Bosh::Director
  module Jobs
    module DynamicDisk
      class BaseJob < Bosh::Director::Jobs::BaseJob
        @queue = :normal

        def nats_client
          Config.nats_rpc
        end
      end
    end
  end
end
