#!/bin/sh
set -e
EDDYHELPER_SCRIPT_FOLDER="$(dirname "$(readlink -f "$0")")"
for script in "${EDDYHELPER_SCRIPT_FOLDER}/scripts/"*.sh; do . "${script}"; done
for script in "${EDDYHELPER_SCRIPT_FOLDER}/scripts/menu/"*.sh; do . "${script}"; done
for script in "${EDDYHELPER_SCRIPT_FOLDER}/scripts/menu/K1/"*.sh; do . "${script}"; done

if [ ! -L /usr/bin/eddynghelper ]; then 
  chmod +x "$EDDYHELPER_SCRIPT_FOLDER"/eddynghelper.sh >/dev/null 2>&1
  ln -sf "$EDDYHELPER_SCRIPT_FOLDER"/eddynghelper.sh /usr/bin/eddynghelper > /dev/null 2>&1
fi
rm -rf /root/.cache
set_paths
set_permissions
# update_menu
main_menu
