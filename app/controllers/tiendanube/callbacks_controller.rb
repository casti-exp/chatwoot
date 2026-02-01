class Tiendanube::CallbacksController < ApplicationController
  include Tiendanube::IntegrationHelper

  def show
    account_id = session.delete(:tiendanube_account_id)
    
    unless account_id.present?
      redirect_to error_url, allow_other_host: true
      return
    end

    account = Account.find(account_id)
    code = params[:code]

    unless code.present?
      redirect_to error_url, allow_other_host: true
      return
    end

    create_tiendanube_hook!(account: account, code: code)
    redirect_to integration_url(account), allow_other_host: true
    
  rescue StandardError => e
    Rails.logger.error("Tiendanube callback error: #{e.message}")
    redirect_to error_url, allow_other_host: true
  end

  private

  def integration_url(account)
    "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/app/accounts/#{account.id}/settings/integrations/tiendanube"
  end

  def error_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end
end
