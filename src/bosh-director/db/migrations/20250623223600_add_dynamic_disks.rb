Sequel.migration do
  up do
    create_table(:dynamic_disks) do
      primary_key :id
      foreign_key :deployment_id, :deployments, :null=>false, :key=>[:id]
      foreign_key :vm_id, :vms, :key=>[:id], :on_delete=>:set_null
      column :disk_cid, 'varchar(255)', :null=>false
      column :name, 'varchar(255)', :null=>false
      column :disk_pool_name, 'varchar(255)', :null=>false
      column :cpi, 'varchar(255)', :default=>''
      column :size, 'integer', :null=>false
      column :metadata_json, 'text'
      column :availability_zone, 'varchar(255)'
      index [:name], :unique=>true
    end
  end

  down do
    delete_table(:dynamic_disks)
  end
end
