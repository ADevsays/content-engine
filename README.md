# Content Engine — n8n One-Click for Dokploy

Deploy this repo from Dokploy to get a fully configured n8n instance with pre-imported workflows and credentials. No manual intervention needed after filling in environment variables.

## How it works

1. **n8n** starts and exposes a healthcheck at `/healthz`.
2. **n8n-importador** waits for n8n to be healthy, then:
   - Resolves `credentials.json.template` with `envsubst` (replaces `${VAR}` placeholders with your env values).
   - Imports the resolved credentials into n8n.
   - Imports all workflows from the `workflows/` directory.
   - Exits with code 0.

## Deployment on Dokploy

1. **Create a Compose project** in Dokploy and point it to this repository.
2. **Fill in environment variables** in the Dokploy panel (see below).
3. **Deploy**. Dokploy handles Traefik routing — no ports needed.
4. **Access n8n** at `https://<your-n8n-domain>` and create your admin account.

## Environment Variables

### Mandatory

| Variable | Description |
|---|---|
| `N8N_DOMAIN` | Domain where n8n will be accessible |
| `N8N_ENCRYPTION_KEY` | Encryption key for stored credentials (generate with `openssl rand -hex 16`) |
| `GENERIC_TIMEZONE` | Timezone (default: `America/Bogota`) |

### Optional — API Keys

These are injected into the credentials template. Leave empty if unused.

| Variable | Service |
|---|---|
| `ELEVENLABS_API_KEY` | ElevenLabs voice generation |
| `TELEGRAM_BOT_TOKEN` | Telegram Bot |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_API_KEY` | Supabase API key |
| `POSTGRES_HOST` | PostgreSQL host |
| `POSTGRES_PORT` | PostgreSQL port (default: 5432) |
| `POSTGRES_DB` | PostgreSQL database name |
| `POSTGRES_USER` | PostgreSQL user |
| `POSTGRES_PASSWORD` | PostgreSQL password |
| `COHERE_API_KEY` | Cohere embeddings API |
| `GOOGLE_GEMINI_API_KEY` | Google Gemini API |
| `NOTION_API_KEY` | Notion integration token |
| `GOOGLE_CLIENT_ID` | Google OAuth2 client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth2 client secret |

## Post-Deployment

1. Go to `https://<your-n8n-domain>` and register your admin account.
2. Activate the workflows you need (they are imported deactivated by default).
3. Configure any remaining credentials directly in the n8n UI if needed.
