#!/bin/sh
set -e

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

echo 'Importando credenciales...'
n8n import:credentials --input=/tmp/credentials_resolved.json

echo 'Importando workflows...'
n8n import:workflow --separate --input=/data/workflows

echo 'Importacion completada exitosamente.'
