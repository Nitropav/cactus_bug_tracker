return if Rails.env.production?

default_password = ENV.fetch("DEFAULT_USER_PASSWORD", "password123")

[
  { name: "Reporter User", email: "reporter@example.com", role: :reporter },
  { name: "Developer User", email: "developer@example.com", role: :developer },
  { name: "Reviewer User", email: "reviewer@example.com", role: :reviewer },
  { name: "Admin User", email: "admin@example.com", role: :admin }
].each do |attributes|
  user = User.find_or_initialize_by(email: attributes[:email])
  user.assign_attributes(
    name: attributes[:name],
    role: attributes[:role],
    password: default_password,
    password_confirmation: default_password
  )
  user.save!
end
