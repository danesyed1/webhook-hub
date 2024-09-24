class CreateDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :deliveries, id: :uuid do |t|
      t.references :event, null: false, foreign_key: true, type: :uuid
      t.references :webhook_endpoint, null: false, foreign_key: true, type: :uuid
      t.string :status, null: false, default: "pending"
      t.integer :attempt_count, null: false, default: 0
      t.datetime :next_attempt_at
      t.timestamps
    end

    add_index :deliveries, [ :event_id, :webhook_endpoint_id ], unique: true
    add_index :deliveries, :status
    add_index :deliveries, :next_attempt_at
    add_index :deliveries, [ :webhook_endpoint_id, :created_at ]
  end
end
