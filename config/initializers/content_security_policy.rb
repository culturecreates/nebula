# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    require 'uri'
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self,
                       "https://cdn.jsdelivr.net",
                       "https://ga.jspm.io",
                       "https://www.googletagmanager.com"
    policy.style_src   :self, :https, :unsafe_inline

    # Helper to extract origin from a URL string
    def origin_of(url)
      return nil unless url
      uri = URI.parse(url)
      return nil unless uri.scheme && uri.host
      port = uri.port && ![80, 443].include?(uri.port) ? ":#{uri.port}" : ""
      "#{uri.scheme}://#{uri.host}#{port}"
    rescue URI::InvalidURIError
      nil
    end

    connect_src_origins = [
      Rails.application.config.graph_api_endpoint,
      Rails.application.config.artsdata_recon_endpoint,
      Rails.application.config.artsdata_recon_endpoint_v0,
      Rails.application.config.artsdata_mint_endpoint,
      Rails.application.config.artsdata_link_endpoint,
      Rails.application.config.artsdata_databus_endpoint,
      Rails.application.config.artsdata_maintenance_endpoint
    ].map { |url| origin_of(url) }.compact.uniq

    policy.connect_src :self, *connect_src_origins, "https://www.google-analytics.com"
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate per-request nonces for permitted importmap and inline scripts
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w(script-src)

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
