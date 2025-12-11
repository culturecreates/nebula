require 'openssl'
require 'base64'
require 'json'
require 'digest'

class BotVerificationController < ApplicationController
  # Load Private Ed25519 Key once
  PRIVATE_KEY_PEM = Base64.decode64(ENV['ED25519_PRIVATE_KEY'])
  PRIVATE_KEY = OpenSSL::PKey.read(PRIVATE_KEY_PEM)

  # Extract Ed25519 Public 'x' coordinate for JWK
  def self.extract_ed25519_x(private_key)
    der = private_key.public_to_der
    raw_key_bytes = der[-32..-1]
    Base64.urlsafe_encode64(raw_key_bytes, padding: false)
  end

  # Calculate JWK Thumbprint (keyid) for HTTP Signatures
  def self.calculate_thumbprint(kty, crv, x)
    jwk = { "crv" => crv, "kty" => kty, "x" => x }
    canonical_json = JSON.generate(jwk.sort.to_h)
    hash = Digest::SHA256.digest(canonical_json)
    Base64.urlsafe_encode64(hash, padding: false)
  end

  KTY = "OKP"
  CRV = "Ed25519"
  X_COORD = extract_ed25519_x(PRIVATE_KEY)
  KEY_ID = calculate_thumbprint(KTY, CRV, X_COORD)

  def http_message_signatures_directory
    authority = request.host_with_port
    nonce = Base64.strict_encode64(OpenSSL::Random.random_bytes(32))
    created = Time.now.to_i
    expires = created + 300

    signature_params = "(\"@authority\");alg=\"ed25519\";keyid=\"#{KEY_ID}\";nonce=\"#{nonce}\";tag=\"http-message-signatures-directory\";created=#{created};expires=#{expires}"
    signing_base = "\"@authority\": #{authority}\n\"@signature-params\": #{signature_params}"

    signature_bytes = PRIVATE_KEY.sign(nil, signing_base)
    signature = Base64.strict_encode64(signature_bytes)

    jwks = {
      keys: [
        {
          kty: KTY,
          crv: CRV,
          x: X_COORD
        }
      ]
    }

    response.headers['Content-Type'] = 'application/http-message-signatures-directory+json'
    response.headers['Signature'] = "sig1=:#{signature}:"
    response.headers['Signature-Input'] = "sig1=#{signature_params}"
    response.headers['Cache-Control'] = 'max-age=86400'
    response.headers['Content-Length'] = jwks.to_json.bytesize.to_s

    render json: jwks
  end
end