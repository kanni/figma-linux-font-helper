#!/bin/bash

echo -e "\n\n"

get_latest_release() {
  curl -Ls --silent "https://github.com/kanni/figma-linux-font-helper/releases/latest" | perl -ne 'print "$1\n" if /v([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,4})/' | head -1;
}

get_latest_release_link_download() {
  local latest=$(get_latest_release);
  echo "http://github.com/kanni/figma-linux-font-helper/releases/download/v${latest}/fonthelper.tar.xz"
}

download() {
  local link=$(get_latest_release_link_download);

  cd /tmp;
  rm -rf ./fonthelper.tar*
  wget "$link";
}

install() {
  mkdir -p /opt/FontHelper
  mkdir -p /etc/figma-linux

  chmod 777 /etc/figma-linux -R

  cat > /etc/figma-linux/fonthelper << EOF
{
  "port": "18412",
  "directories": [
    "/usr/share/fonts",
    "$HOME/.local/share/fonts"
  ]
}
EOF

  cd /opt/FontHelper;
  tar xJf /tmp/fonthelper.tar.xz ./fonthelper
  tar xJf /tmp/fonthelper.tar.xz ./updater.sh
  tar xJf /tmp/fonthelper.tar.xz ./libfreetype.so.6
  chmod +x ./fonthelper ./updater.sh

  cd /lib/systemd/system
  tar xJf /tmp/fonthelper.tar.xz ./fonthelper.service
  tar xJf /tmp/fonthelper.tar.xz ./fonthelper-updater.service

  chmod 644 /lib/systemd/system/fonthelper.service
  chmod 644 /lib/systemd/system/fonthelper-updater.service

  systemctl daemon-reload

  systemctl start fonthelper.service
  systemctl start fonthelper-updater.service

  systemctl enable fonthelper.service
  systemctl enable fonthelper-updater.service

  rm -rf ./fonthelper.tar*
}

main() {
  if [[ $EUID -eq 0 ]]; then
    echo "Run script under non-root user";
    echo "Abort";
    exit 1;
  fi

  download;
  sudo bash -c "$(declare -f install); install"
}

main;
