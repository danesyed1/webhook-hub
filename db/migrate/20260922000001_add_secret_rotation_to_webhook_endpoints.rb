class AddSecretRotationToWebhookEndpoints < ActiveRecord::Migration[8.1]
  def change
    add_column :webhook_endpoints, :previous_signing_secret, :string
    add_column :webhook_endpoints, :previous_secret_expires_at, :datetime
  end
end
