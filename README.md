# n8n Installer with Workflows

This repository provides a complete setup to run your own n8n instance using Docker, pre-configured and ready to import a set of useful workflows.

## Prerequisites
- A VPS with Docker installed.
- A domain or subdomain pointed to your VPS IP.

## Installation

### Option 1: Quick Install (via curl)
Run the following command directly on your VPS. It will guide you through cloning and setting up the project:
```bash
curl -sSL https://raw.githubusercontent.com/<your-username>/<your-repo-name>/main/install.sh | bash
```

---

### Option 2: Manual Installation

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd <repo-name>
   ```

2. **Configure environment:**
   Copy the example environment file and fill in your details:
   ```bash
   cp .env.example .env
   nano .env
   ```
   *Make sure to configure `N8N_DOMAIN` and a secure random key for `N8N_ENCRYPTION_KEY`.*

3. **Run the installer:**
   Execute the installation script. This will start n8n and import the workflows.
   ```bash
   bash install.sh
   ```

---

## Post-Installation Steps

1. **Access n8n:**
   Go to `https://<your-n8n-domain>` and register your initial owner/admin account through the setup wizard.

2. **Finalize configuration:**
   - Configure any missing credentials inside n8n for your active nodes (OpenAI, Google, Telegram, etc.).
   - Activate your workflows (they are imported in a deactivated state by default).
