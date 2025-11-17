class BotVerificationController < ApplicationController
  def http_message_signatures_directory
    response.headers['Content-Type'] = 'application/http-message-signatures-directory+json'
    response.headers['Signature'] = 'sig1=:TD5arhV1ved6xtx63cUIFCMONT248cpDeVUAljLgkdozbjMNpJGr/WAx4PzHj+WeG0xMHQF1BOdFLDsfjdjvBA==:'
    response.headers['Signature-Input'] = 'sig1=("@authority");alg="ed25519";keyid="poqkLGiymh_W0uP6PZFw-dvez3QJT5SolqXBCW38r0U";nonce="ZO3/XMEZjrvSnLtAP9M7jK0WGQf3J+pbmQRUpKDhF9/jsNCWqUh2sq+TH4WTX3/GpNoSZUa8eNWMKqxWp2/c2g==";tag="http-message-signatures-directory";created=1750105829;expires=1750105839'
    response.headers['Cache-Control'] = 'max-age=86400'

    render json: {
      keys: [{
        kty: "OKP",
        crv: "Ed25519",
        x: "JrQLj5P_89iXES9-vFgrIy29clF9CC_oPPsw3c5D0bs"
      }]
    }
  end
end