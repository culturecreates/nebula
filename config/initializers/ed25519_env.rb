if Rails.application.credentials.ed25519_private_key && ENV['ED25519_PRIVATE_KEY'].nil?
  ENV['ED25519_PRIVATE_KEY'] = Rails.application.credentials.ed25519_private_key
end