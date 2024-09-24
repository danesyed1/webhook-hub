class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events, id: :uuid do |t|
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :status, null: false, default: "queued"
      t.timestamps
    end

    add_index :events, [ :project_id, :created_at ]
    add_index :events, :status
  end
end
