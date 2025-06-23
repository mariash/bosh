module Bosh::Director::Models
  class DynamicDisk < Sequel::Model(Bosh::Director::Config.db)
    many_to_one :deployment

    def validate
      validates_presence [:disk_name, :disk_cid]
      validates_unique [:disk_name, :disk_cid]
    end

    def to_s
      "#{self.name}/#{self.disk_cid}"
    end
  end
end
