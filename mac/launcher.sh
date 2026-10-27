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
MARCA="$PERFIL/.abertura_auto_ignorada"

mkdir -p "$PERFIL"

# Há quanto tempo esta sessão foi aberta. Usa o loginwindow, que nasce junto
# com o login. (A data de /dev/console não serve: ela muda a cada mensagem
# que o sistema escreve no console, ou seja, o tempo todo.)
segundos_desde_login() {
  local pid tempo
  pid=$(pgrep -x loginwindow | head -1)
  [ -n "$pid" ] || return 1
  tempo=$(ps -o etime= -p "$pid" 2>/dev/null | tr -d '[:space:]')
  [ -n "$tempo" ] || return 1
  printf '%s\n' "$tempo" | awk -F'[-:]' '
    NF==4 { print $1*86400 + $2*3600 + $3*60 + $4; exit }
    NF==3 { print $1*3600 + $2*60 + $3; exit }
    NF==2 { print $1*60 + $2; exit }
    { exit 1 }'
}

# O macOS relança os apps logo após o login ("Reabrir janelas ao entrar").
# Ignora só essa primeira abertura automática, nos 30 s seguintes ao login.
# Na dúvida (não deu para medir), abre: é melhor abrir a mais do que o ícone
# não responder ao clique.
DESDE_LOGIN=$(segundos_desde_login)
if [ -n "$DESDE_LOGIN" ] && [ "$DESDE_LOGIN" -lt 30 ]; then
  IDADE_MARCA=999999
  if [ -f "$MARCA" ]; then
    IDADE_MARCA=$(( $(date +%s) - $(stat -f %m "$MARCA") ))
  fi
  # Marca mais velha que o login: é de uma sessão anterior, não vale.
  if [ "$IDADE_MARCA" -gt "$DESDE_LOGIN" ]; then
    touch "$MARCA"
    exit 0
  fi
fi

if [ ! -x "$CHROME" ]; then
  # Sem Chrome: abre no navegador padrão.
  exec open "$URL"
fi

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
