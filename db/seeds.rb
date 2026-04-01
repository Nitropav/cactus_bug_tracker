return if Rails.env.production?

default_password = ENV.fetch("DEFAULT_USER_PASSWORD", "password123")

[
  { name: "Customer User", email: "customer@example.com", role: :customer, legacy_email: "reporter@example.com" },
  { name: "Developer User", email: "developer@example.com", role: :developer },
  { name: "Support Agent User", email: "support_agent@example.com", role: :support_agent, legacy_email: "reviewer@example.com" },
  { name: "Admin User", email: "admin@example.com", role: :admin }
].each do |attributes|
  user = User.find_by(email: attributes[:email])
  user ||= User.find_by(email: attributes[:legacy_email]) if attributes[:legacy_email].present?
  user ||= User.new

  user.assign_attributes(
    name: attributes[:name],
    email: attributes[:email],
    role: attributes[:role],
    password: default_password,
    password_confirmation: default_password
  )
  user.save!
end
