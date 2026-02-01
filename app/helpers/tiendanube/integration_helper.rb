module Tiendanube::IntegrationHelper
  def create_tiendanube_hook!(account:, code:)
    token_data = exchange_code_for_token(code)
    
    account.hooks.create!(
      app_id: 'tiendanube',
      access_token: token_data['access_token'],
      reference_id: token_data['user_id'].to_s,
      status: 'enabled',
      settings: {
        store_id: token_data['user_id']
      }
    )
  end

  private

  def exchange_code_for_token(code)
    client_id = GlobalConfigService.load('TIENDANUBE_CLIENT_ID', nil)
    client_secret = GlobalConfigService.load('TIENDANUBE_CLIENT_SECRET', nil)

    response = HTTParty.post(
      'https://www.tiendanube.com/apps/authorize/token',
      headers: { 'Content-Type' => 'application/json' },
      body: {
        client_id: client_id,
        client_secret: client_secret,
        grant_type: 'authorization_code',
        code: code
      }.to_json,
      timeout: 10
    )

    unless response.success?
      raise StandardError, "Tiendanube OAuth failed: HTTP #{response.code}"
    end

    data = JSON.parse(response.body)
    
    unless data['access_token'].present? && data['user_id'].present?
      raise StandardError, "Invalid Tiendanube OAuth response: missing credentials"
    end

    data
    
  rescue JSON::ParserError => e
    Rails.logger.error("Tiendanube token parse error: #{e.message}")
    raise StandardError, 'Invalid OAuth response format'
  rescue HTTParty::Error, Net::OpenTimeout => e
    Rails.logger.error("Tiendanube OAuth request error: #{e.message}")
    raise StandardError, 'OAuth request failed'
  end
end
