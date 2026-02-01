# Tienda Nube Integration for RedChat/Chatwoot

## Overview

This integration allows you to connect your Tienda Nube store to RedChat/Chatwoot CRM, enabling:
- View customer orders in the conversation sidebar
- Access order details (status, total, date)
- Quick links to order admin pages
- Automatic order matching by email or phone

## Setup Instructions

### 1. Create Tienda Nube Partner App

1. Go to [https://partners.tiendanube.com](https://partners.tiendanube.com)
2. Register as a Partner (if you don't have an account)
3. Create a new app:
   - **Name**: RedChat CRM (or your preferred name)
   - **Redirect URL**: `{YOUR_FRONTEND_URL}/tiendanube/callback`
     - Local development: `http://localhost:3000/tiendanube/callback`
     - Production: `https://your-domain.com/tiendanube/callback`
   - **Permissions**: 
     - ✅ Read orders
     - ✅ Read products (optional)
     - ✅ Read customers (optional)

4. After creating the app, copy:
   - **App ID** (Client ID)
   - **Client Secret**

### 2. Configure Environment Variables

Add the following to your `.env` file:

```bash
TIENDANUBE_CLIENT_ID=your_app_id_here
TIENDANUBE_CLIENT_SECRET=your_client_secret_here
```

### 3. Run the Application

```bash
# If using Docker Compose
docker-compose up -d

# Wait for services to start (2-3 minutes)

# Create admin user (first time only)
docker-compose exec rails bundle exec rails db:chatwoot_prepare

# Access the application
open http://localhost:3000
```

### 4. Connect Your Store

1. Login to Chatwoot
2. Go to **Settings → Integrations → Tienda Nube**
3. Click **"Connect"**
4. You'll be redirected to Tienda Nube
5. Authorize the app
6. You'll be redirected back to Chatwoot

### 5. Test the Integration

1. Create or open a conversation
2. Make sure the contact has an **email** or **phone number**
3. In the sidebar, you should see **Tienda Nube Orders**
4. Orders from that customer will appear automatically

## Technical Details

### Architecture

**Backend (Rails):**
- `app/controllers/api/v1/accounts/integrations/tiendanube_controller.rb` - API endpoints
- `app/controllers/tiendanube/callbacks_controller.rb` - OAuth callback handler
- `app/helpers/tiendanube/integration_helper.rb` - OAuth token exchange
- `lib/integrations/tiendanube/orders_builder.rb` - Orders fetching and matching logic

**Frontend (Vue 3):**
- `app/javascript/dashboard/routes/dashboard/settings/integrations/Tiendanube.vue` - Settings page
- `app/javascript/dashboard/components/widgets/conversation/TiendanubeOrdersList.vue` - Orders list
- `app/javascript/dashboard/components/widgets/conversation/TiendanubeOrderItem.vue` - Individual order card
- `app/javascript/dashboard/api/integrations/tiendanube.js` - API client

**Routes:**
- `POST /api/v1/accounts/{account_id}/integrations/tiendanube/auth` - Initialize OAuth
- `GET /api/v1/accounts/{account_id}/integrations/tiendanube/orders` - Fetch orders
- `DELETE /api/v1/accounts/{account_id}/integrations/tiendanube` - Disconnect
- `GET /tiendanube/callback` - OAuth callback

### Features

✅ **OAuth 2.0 Authentication**
- Secure token storage per account
- Multi-tenant isolation

✅ **Order Matching**
- By email (priority)
- By phone number (fallback)
- Cache: 3 minutes TTL

✅ **Performance**
- Limits to 20 most recent orders
- API field filtering (only necessary data)
- Smart caching strategy

✅ **Error Handling**
- Timeout protection (10s)
- Connection failure recovery
- User-friendly error messages

### Data Flow

```
1. User clicks "Connect" → Frontend
2. Backend generates OAuth URL → Tienda Nube
3. User authorizes → Tienda Nube callback
4. Backend exchanges code for token → Saves in database
5. User opens conversation → Frontend requests orders
6. Backend fetches from Tienda Nube API → Returns normalized data
7. Frontend displays orders in sidebar
```

### Security

- ✅ OAuth 2.0 with secure token storage
- ✅ Multi-tenant isolation (each account has own credentials)
- ✅ Admin-only integration management
- ✅ No credentials in logs
- ✅ Encrypted access tokens in database

## Known Limitations

1. **Admin URL**: Currently uses a generic Tienda Nube URL pattern. May need adjustment for specific store URLs.
2. **No Webhooks**: Orders are fetched on-demand, not pushed via webhooks (future enhancement).
3. **Cache Duration**: 3 minutes - balance between freshness and API calls.

## Troubleshooting

### Orders not showing up

**Check:**
1. Is the integration connected? (Settings → Integrations → Tienda Nube → should say "Connected")
2. Does the contact have an email or phone number?
3. Does that email/phone match orders in your Tienda Nube store?
4. Check browser console for errors (F12 → Console tab)
5. Check Rails logs: `docker-compose logs -f rails`

### OAuth callback fails

**Check:**
1. Redirect URL in Tienda Nube Partner app matches your FRONTEND_URL
2. TIENDANUBE_CLIENT_ID and TIENDANUBE_CLIENT_SECRET are correctly set
3. Session cookies are enabled in browser

### API errors

**Check:**
1. Access token is valid (try disconnecting and reconnecting)
2. Tienda Nube API is accessible (check `https://api.tiendanube.com/v1/{store_id}/orders`)
3. Rate limits not exceeded

## Future Enhancements

- [ ] Webhooks for real-time order updates
- [ ] Product information in sidebar
- [ ] Customer lifetime value calculations
- [ ] Order creation from Chatwoot
- [ ] Abandoned cart recovery
- [ ] Feature flags for gradual rollout

## Development

```bash
# Clone repo
git clone https://github.com/casti-exp/chatwoot.git redchat
cd redchat

# Checkout integration branch
git checkout feature/tiendanube-integration

# Configure
cp .env.example .env
# Edit .env with your Tienda Nube credentials

# Run
docker-compose up

# Access
open http://localhost:3000
```

## Credits

Integration developed by Jimmy AI for RedChat.
Based on Chatwoot's Shopify integration pattern.

## Support

For issues or questions:
- GitHub Issues: [github.com/casti-exp/chatwoot/issues](https://github.com/casti-exp/chatwoot/issues)
- Email: support@redchat.ai
