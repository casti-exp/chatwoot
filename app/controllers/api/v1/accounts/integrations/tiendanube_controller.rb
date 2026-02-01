class Api::V1::Accounts::Integrations::TiendanubeController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :fetch_hook, only: [:destroy, :orders]
  before_action :validate_contact, only: [:orders]

  def auth
    # Store account_id in session for OAuth callback
    session[:tiendanube_account_id] = Current.account.id
    
    render json: {
      redirect_url: tiendanube_authorize_url
    }
  end

  def orders
    orders = Integrations::Tiendanube::OrdersBuilder.new(
      hook: @hook,
      contact: @contact
    ).fetch_orders

    render json: { orders: orders }
  rescue Integrations::Tiendanube::OrdersBuilder::Error => e
    Rails.logger.error("Tiendanube orders error: #{e.message}")
    render json: { error: I18n.t('integration_apps.tiendanube.errors.fetch_orders') },
           status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error("Unexpected Tiendanube error: #{e.message}")
    render json: { error: I18n.t('integration_apps.tiendanube.errors.unexpected') },
           status: :internal_server_error
  end

  def destroy
    @hook.destroy!
    head :ok
  end

  private

  def fetch_hook
    @hook = Current.account.hooks.find_by!(app_id: 'tiendanube')
  end

  def validate_contact
    @contact = Current.account.contacts.find_by(id: params[:contact_id])
    
    if @contact.blank? || (@contact.email.blank? && @contact.phone_number.blank?)
      render json: { 
        error: I18n.t('integration_apps.tiendanube.errors.contact_data_missing') 
      }, status: :unprocessable_entity
      return
    end
  end

  def tiendanube_authorize_url
    client_id = GlobalConfigService.load('TIENDANUBE_CLIENT_ID', nil)
    "https://www.tiendanube.com/apps/#{client_id}/authorize"
  end
end
