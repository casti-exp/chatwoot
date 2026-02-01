class Integrations::Tiendanube::OrdersBuilder
  class Error < StandardError; end
  
  MAX_ORDERS = 20
  CACHE_TTL = 3.minutes
  API_TIMEOUT = 10

  def initialize(hook:, contact:)
    @hook = hook
    @contact = contact
  end

  def fetch_orders
    return [] unless searchable?

    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) do
      begin
        all_orders = fetch_recent_orders
        matched_orders = match_orders(all_orders)
        matched_orders.first(MAX_ORDERS).map { |order| normalize_order(order) }
      rescue => e
        Rails.logger.error("OrdersBuilder error: #{e.message}")
        []
      end
    end
  end

  private

  attr_reader :hook, :contact

  def cache_key
    [
      'tiendanube',
      'orders',
      hook.reference_id,
      contact.id,
      contact.email.presence || contact.phone_number
    ].compact.join(':')
  end

  def searchable?
    contact.email.present? || contact.phone_number.present?
  end

  def match_orders(orders)
    # Priority: email first, then phone
    if contact.email.present?
      orders.select { |order| email_matches?(order) }
    elsif contact.phone_number.present?
      orders.select { |order| phone_matches?(order) }
    else
      []
    end
  end

  def email_matches?(order)
    order_email = order['contact_email'].to_s.strip.downcase
    contact_email = contact.email.to_s.strip.downcase
    order_email == contact_email
  end

  def phone_matches?(order)
    order_phone = normalize_phone(order.dig('shipping_address', 'phone'))
    contact_phone = normalize_phone(contact.phone_number)
    order_phone.present? && order_phone == contact_phone
  end

  def normalize_phone(phone)
    phone.to_s.gsub(/\D/, '')
  end

  def fetch_recent_orders
    response = api_connection.get('orders') do |req|
      req.params['limit'] = MAX_ORDERS * 2 # Fetch more to ensure matches
      req.params['fields'] = 'id,number,status,payment_status,fulfillment_status,created_at,contact_email,shipping_address,total,currency'
      req.options.timeout = API_TIMEOUT
    end

    if response.success?
      response.body || []
    else
      Rails.logger.error("Tiendanube API error: HTTP #{response.status}")
      raise Error, "API returned status #{response.status}"
    end
    
  rescue Faraday::TimeoutError
    Rails.logger.error('Tiendanube API timeout')
    raise Error, 'API request timeout'
  rescue Faraday::ConnectionFailed => e
    Rails.logger.error("Tiendanube connection failed: #{e.message}")
    raise Error, 'Connection failed'
  end

  def api_connection
    @api_connection ||= Faraday.new(
      url: "https://api.tiendanube.com/v1/#{store_id}",
      headers: {
        'Authentication' => "bearer #{hook.access_token}",
        'User-Agent' => 'RedChat CRM (support@redchat.ai)',
        'Content-Type' => 'application/json'
      }
    ) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  def store_id
    hook.reference_id
  end

  def normalize_order(order)
    {
      id: order['number'] || order['id'],
      external_id: order['id'],
      financial_status: map_financial_status(order['payment_status']),
      fulfillment_status: map_fulfillment_status(order['fulfillment_status']),
      total_price: order['total'],
      currency: order['currency'] || 'ARS',
      created_at: order['created_at'],
      admin_url: build_admin_url(order['id'])
    }
  end

  def build_admin_url(order_id)
    # Use store_id from hook to build dynamic URL
    # Format: https://tiendaXXXXX.mitiendanube.com/admin/orders/ORDER_ID
    "https://www.tiendanube.com/#{store_id}/admin/orders/#{order_id}"
  end

  def map_financial_status(payment_status)
    case payment_status.to_s
    when 'paid'
      'paid'
    when 'pending'
      'pending'
    when 'cancelled', 'refunded', 'voided'
      'refunded'
    else
      'pending'
    end
  end

  def map_fulfillment_status(fulfillment_status)
    case fulfillment_status.to_s
    when 'fulfilled'
      'fulfilled'
    when 'unfulfilled'
      'unfulfilled'
    when 'partial'
      'partial'
    else
      'unfulfilled'
    end
  end
end
