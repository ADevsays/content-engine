#!/bin/sh
set -e

# ─── 1. Resolve credentials template ────────────────────────────────────────
echo 'Resolviendo template de credenciales...'
awk '{
  line = $0
  while (match(line, /\$\{[A-Za-z_][A-Za-z_0-9]*\}/)) {
    var = substr(line, RSTART+2, RLENGTH-3)
    val = ENVIRON[var]
    line = substr(line, 1, RSTART-1) val substr(line, RSTART+RLENGTH)
  }
  print line
}' /data/credentials.json.template > /tmp/credentials_resolved.json

# ─── 2. Run Supabase / Postgres schema migration ────────────────────────────
echo 'Ejecutando migracion de base de datos...'
PG_MODULE=$(find /usr/local/lib/node_modules -name "index.js" -path "*/pg/lib/index.js" 2>/dev/null | head -1 | sed 's|/lib/index.js||')

node -e "
const { Client } = require('${PG_MODULE}');
const fs = require('fs');

const client = new Client({
  host:     process.env.POSTGRES_HOST,
  port:     parseInt(process.env.POSTGRES_PORT || '5432'),
  database: process.env.POSTGRES_DB,
  user:     process.env.POSTGRES_USER,
  password: process.env.POSTGRES_PASSWORD,
  ssl:      { rejectUnauthorized: false }
});

const sql = fs.readFileSync('/data/schema.sql', 'utf8');

client.connect()
  .then(() => client.query(sql))
  .then(() => { console.log('Migracion completada.'); return client.end(); })
  .catch(err => { console.error('Error en migracion:', err.message); process.exit(1); });
"

# ─── 3. Import credentials ───────────────────────────────────────────────────
echo 'Importando credenciales...'
n8n import:credentials --input=/tmp/credentials_resolved.json

# ─── 4. Import workflows ─────────────────────────────────────────────────────
echo 'Importando workflows...'
n8n import:workflow --separate --input=/data/workflows

echo 'Importacion completada exitosamente.'
