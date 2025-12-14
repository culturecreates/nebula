require 'openssl'
require 'base64'
require 'json'
require 'digest'


# Cloudflare tool to test the endpoint - https://crates.io/crates/http-signature-directory
# after installation run with:
# http-signature-directory your-domain.com/.well-known/http-message-signatures-directory
# example - http-signature-directory https://cycling-troubleshooting-vertex-resumes.trycloudflare.com/.well-known/http-message-signatures-directory
# the endpoint should return a valid JWKS and HTTP Signature headers, should be HTTPS

class BotVerificationController < ApplicationController
  # Load Private Ed25519 Key once
  PRIVATE_KEY_ENCODED = ENV['ED25519_PRIVATE_KEY']
  raise "ED25519_PRIVATE_KEY is not set" if PRIVATE_KEY_ENCODED.nil?

  PRIVATE_KEY_PEM = Base64.decode64(PRIVATE_KEY_ENCODED)    # Read private key PEM file
  PRIVATE_KEY = OpenSSL::PKey.read(PRIVATE_KEY_PEM)         # Parse PEM into OpenSSL key object

  # Extract Ed25519 Public 'x' coordinate for JWK
  def self.extract_ed25519_x(private_key)
    der = private_key.public_to_der                        # Convert to DER to access raw bytes
    raw_key_bytes = der[-32..-1]                           # Extract last 32 bytes (raw public key)
    Base64.urlsafe_encode64(raw_key_bytes, padding: false) # Return base64url encoded value
  end

  # Calculate JWK Thumbprint (keyid) for HTTP Signatures
  def self.calculate_thumbprint(kty, crv, x)
    jwk = { "crv" => crv, "kty" => kty, "x" => x }
    canonical_json = JSON.generate(jwk.sort.to_h)         # Canonical JSON per RFC, sorting to ensure order of keys
    hash = Digest::SHA256.digest(canonical_json)          # SHA-256 hash of canonical JWK
    Base64.urlsafe_encode64(hash, padding: false)         # Base64url encode without padding
  end

  # Key Metadata Used for JWKS Output
  KTY = "OKP"           # Key type for Ed25519
  CRV = "Ed25519"        # Curve name
  X_COORD = extract_ed25519_x(PRIVATE_KEY)
  KEY_ID = calculate_thumbprint(KTY, CRV, X_COORD)

  # Well-Known Endpoint for Message Signatures Directory
  # Serves a JWKS and HTTP Message Signature (sig1)
  def http_message_signatures_directory
    authority = request.host_with_port
    nonce = Base64.strict_encode64(OpenSSL::Random.random_bytes(32))
    created = Time.now.to_i
    expires = created + 300

    # Build Signature-Input parameter string
    signature_params = "(\"@authority\");alg=\"ed25519\";keyid=\"#{KEY_ID}\";nonce=\"#{nonce}\";tag=\"http-message-signatures-directory\";created=#{created};expires=#{expires}"
    
    # Construct signing base string according to HTTP Signatures spec
    signing_base = "\"@authority\": #{authority}\n\"@signature-params\": #{signature_params}"

    # Sign the string using Ed25519 private key
    signature_bytes = PRIVATE_KEY.sign(nil, signing_base)
    signature = Base64.strict_encode64(signature_bytes)

    # JWKS body with only public key parameters
    jwks = {
      keys: [
        {
          kty: KTY,
          crv: CRV,
          x: X_COORD
        }
      ]
    }

    # Response Headers
    response.headers['Content-Type'] = 'application/http-message-signatures-directory+json'
    response.headers['Signature'] = "sig1=:#{signature}:"
    response.headers['Signature-Input'] = "sig1=#{signature_params}"
    response.headers['Cache-Control'] = 'max-age=86400'
    response.headers['Content-Length'] = jwks.to_json.bytesize.to_s

    render json: jwks
  end
end