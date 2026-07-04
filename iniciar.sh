#!/bin/bash
# Inicia o AMiGO Corretor via servidor local (necessário para o Google Drive funcionar)

PORT=8080
DIR="$(cd "$(dirname "$0")" && pwd)"

# Verifica se a porta já está em uso
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
  echo "Servidor já rodando na porta $PORT"
else
  echo "Iniciando servidor na porta $PORT..."
  cd "$DIR"
  python3 -m http.server $PORT --bind 127.0.0.1 >/dev/null 2>&1 &
  sleep 1
fi

# Abre no navegador padrão
open "http://localhost:$PORT/index.html"
