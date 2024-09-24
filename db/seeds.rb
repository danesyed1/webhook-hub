user = User.find_or_create_by!(email: "demo@webhookhub.dev") do |u|
  u.name = "Demo User"
  u.password = "password123"
  u.password_confirmation = "password123"
end

org = Organization.find_or_create_by!(slug: "acme") do |o|
  o.name = "Acme"
end

Membership.find_or_create_by!(user:, organization: org) do |m|
  m.role = "owner"
end

project = Project.find_or_create_by!(organization: org, name: "Production") do |p|
  p.description = "Production environment"
end

EventType::SEED_TYPES.each do |name|
  project.event_types.find_or_create_by!(name:)
end

api_key, raw_key = ApiKey.generate_for(project)
api_key.name = "Default"
api_key.save!

puts "Demo user: demo@webhookhub.dev / password123"
puts "API key: #{raw_key}"
