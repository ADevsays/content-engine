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

node --dns-result-order=ipv4first -e "
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
const statements = sql
  .split(';')
  .map(s => s.trim())
  .filter(s => s.length > 0);

(async () => {
  await client.connect();
  console.log('[DB] Conectado a PostgreSQL');

  let success = 0;
  let failed = 0;

  for (const stmt of statements) {
    const tableMatch = stmt.match(/CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\S+)/i);
    const label = tableMatch ? tableMatch[1] : stmt.substring(0, 50);

    try {
      await client.query(stmt);
      console.log('[OK] ' + label);
      success++;
    } catch (err) {
      console.error('[ERROR] ' + label + ' -> ' + err.message);
      failed++;
    }
  }

  await client.end();
  console.log('[DB] Migracion finalizada: ' + success + ' exitosas, ' + failed + ' errores');

  if (failed > 0) process.exit(1);
})();
"


# ─── 3. Import credentials ───────────────────────────────────────────────────
echo 'Importando credenciales...'
n8n import:credentials --input=/tmp/credentials_resolved.json

# ─── 4. Import workflows ─────────────────────────────────────────────────────
echo 'Importando workflows...'
n8n import:workflow --separate --input=/data/workflows

echo 'Importacion completada exitosamente.'
