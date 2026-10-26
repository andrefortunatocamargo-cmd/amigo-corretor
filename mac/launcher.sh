#!/bin/bash
# AMiGO Corretor — abre o sistema em janela própria, sem barra de endereço.
#
# O sistema fica no GitHub Pages e usa Firebase, então não depende de servidor
# local: funciona de qualquer rede, e os dados são os mesmos do celular.

URL="https://andrefortunatocamargo-cmd.github.io/amigo-corretor/"

# O GitHub Pages manda guardar a página por 10 minutos. Depois de uma
# atualização, a janela abria a versão velha e a novidade "não existia".
# Abrir com um carimbo de tempo força o Chrome a buscar a versão atual.
# Mesma origem, então os dados salvos (clientes, fotos) continuam os mesmos.
URL_ABERTURA="${URL}index.html?v=$(date +%s)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
PERFIL="$HOME/Library/Application Support/AMiGOCorretor"

# O macOS relança os apps logo após o login ("Reabrir janelas ao entrar").
# Ignora só essa primeira abertura automática, nos 30 s seguintes ao login.
LOGIN=$(stat -f %m /dev/console 2>/dev/null)
AGORA=$(date +%s)
MARCA="$PERFIL/.abertura_auto_ignorada"
if [ -n "$LOGIN" ] && [ $((AGORA - LOGIN)) -lt 30 ] && { [ ! -f "$MARCA" ] || [ "$MARCA" -ot /dev/console ]; }; then
  mkdir -p "$PERFIL"
  touch "$MARCA"
  exit 0
fi

if [ -x "$CHROME" ]; then
  # Janela dedicada, com perfil próprio: o login do sistema não se mistura
  # com as abas e contas do Chrome do dia a dia.
  mkdir -p "$PERFIL"
  exec "$CHROME" \
    --app="$URL_ABERTURA" \
    --user-data-dir="$PERFIL" \
    --no-first-run \
    --no-default-browser-check \
    --window-size=1440,900
else
  # Sem Chrome: abre no navegador padrão.
  exec open "$URL"
fi
