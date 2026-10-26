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
CHROME_APP="/Applications/Google Chrome.app"
CHROME="$CHROME_APP/Contents/MacOS/Google Chrome"
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

if [ ! -x "$CHROME" ]; then
  # Sem Chrome: abre no navegador padrão.
  exec open "$URL"
fi

mkdir -p "$PERFIL"

EM_USO=$(pgrep -f -- "--user-data-dir=$PERFIL" | head -1)
if [ -n "$EM_USO" ]; then
  # Já existe uma instância com este perfil. Pedir a ela que abra a janela
  # não resolve: se a janela estiver minimizada, nada aparece — e clicar no
  # ícone tem de mostrar o sistema. Duas instâncias também não podem dividir
  # o mesmo perfil (acontece quando o Chrome se atualiza com a janela aberta,
  # e o resultado é justamente uma janela em branco).
  #
  # Então encerra com jeito e reabre. Os dados ficam salvos: o sistema grava
  # cada alteração no próprio navegador, e o TERM dá tempo de concluir.
  pkill -f -- "--user-data-dir=$PERFIL"
  for _ in $(seq 1 24); do
    pgrep -f -- "--user-data-dir=$PERFIL" >/dev/null || break
    sleep 0.5
  done
  # Se insistir em continuar de pé, força: um perfil preso impede a abertura.
  pgrep -f -- "--user-data-dir=$PERFIL" >/dev/null && {
    pkill -9 -f -- "--user-data-dir=$PERFIL"
    sleep 1
  }
fi

# Janela dedicada, com perfil próprio: o login do sistema não se mistura
# com as abas e contas do Chrome do dia a dia.
exec "$CHROME" \
  --app="$URL_ABERTURA" \
  --user-data-dir="$PERFIL" \
  --no-first-run \
  --no-default-browser-check \
  --window-size=1440,900
