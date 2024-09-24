class CreateDeliveryAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_attempts, id: :uuid do |t|
      t.references :delivery, null: false, foreign_key: true, type: :uuid
      t.integer :attempt_number, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :http_status
      t.text :response_body
      t.jsonb :response_headers, default: {}
      t.string :error_message
      t.integer :duration_ms
      t.boolean :success, null: false, default: false
      t.timestamps
    end

    add_index :delivery_attempts, [ :delivery_id, :attempt_number ]
    # delivery_id index is created automatically by t.references above
  end
end
