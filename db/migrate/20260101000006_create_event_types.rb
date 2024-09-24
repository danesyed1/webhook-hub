class CreateEventTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :event_types, id: :uuid do |t|
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :description
      t.timestamps
    end

    add_index :event_types, [ :project_id, :name ], unique: true
  end
end
