class CreateWebhookEndpoints < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_endpoints, id: :uuid do |t|
      t.references :project, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :url, null: false
      t.string :description
      t.boolean :enabled, null: false, default: true
      t.string :signing_secret, null: false
      t.string :signing_secret_prefix, null: false
      t.timestamps
    end

    # project_id index is created automatically by t.references above
  end
end
