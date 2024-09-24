class CreateEndpointEventTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :endpoint_event_types, id: :uuid do |t|
      t.references :webhook_endpoint, null: false, foreign_key: true, type: :uuid
      t.references :event_type, null: false, foreign_key: true, type: :uuid
      t.timestamps
    end

    add_index :endpoint_event_types, [ :webhook_endpoint_id, :event_type_id ], unique: true, name: "idx_endpoint_event_types_unique"
  end
end
