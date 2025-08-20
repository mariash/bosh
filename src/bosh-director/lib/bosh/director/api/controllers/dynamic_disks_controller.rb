require 'bosh/director/api/controllers/base_controller'

module Bosh::Director
  module Api::Controllers
    class DynamicDisksController < BaseController
      include ValidationHelper

      post '/provide', consumes: :json do
        request_hash = JSON.parse(request.body.read)

        instance_id = safe_property(request_hash, "instance_id", class: String, min_length: 1)
        disk_name = safe_property(request_hash, "disk_name", class: String, min_length: 1)
        disk_pool_name = safe_property(request_hash, "disk_pool_name", class: String, min_length: 1)
        disk_size = safe_property(request_hash, "disk_size", class: Integer, min: 1)
        metadata = safe_property(request_hash, "metadata", class: Hash, optional: true)

        task = JobQueue.new.enqueue(
          current_user,
          Jobs::DynamicDisks::ProvideDynamicDisk,
          'provide dynamic disk',
          [instance_id, disk_name, disk_pool_name, disk_size, metadata]
        )

        redirect "/tasks/#{task.id}"
      end

      # def parse_config
      #   config_hash = parse_request_body(request.body.read)
      #   validate_type_and_name(config_hash)
      #   content_hash = parse_config_content(config_hash['content'])
      #   config_hash['content'] = ensure_release_version_is_string(content_hash) if config_hash['type'] == 'runtime'
      #
      #   config_hash
      # rescue StandardError => e
      #   type = config_hash && config_hash['type']
      #   name = config_hash && config_hash['name']
      #   create_event(type, name, e)
      #   raise e
      # end

      # post '/:disk_name/detach', scope: :manage_dynamic_disks, consumes: :json do
      #   task = JobQueue.new.enqueue(
      #     current_user,
      #     Jobs::DynamicDisks::DetachDynamicDisk,
      #     'detach dynamic disk',
      #     [params[:disk_name]]
      #   )
      #
      #   redirect "/tasks/#{task.id}"
      # end
      #
      # delete '/:disk_name', scope: :manage_dynamic_disks, consumes: :json do
      #   task = JobQueue.new.enqueue(
      #     current_user,
      #     Jobs::DynamicDisks::DeleteDynamicDisk,
      #     'delete dynamic disk',
      #     [params[:disk_name]]
      #   )
      #
      #   redirect "/tasks/#{task.id}"
      # end
    end
  end
end
