class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects, id: :uuid do |t|
      t.references :organization, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :description
      t.timestamps
    end

    add_index :projects, [ :organization_id, :name ], unique: true
  end
end
