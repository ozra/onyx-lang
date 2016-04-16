#!/usr/bin/env bash

echo "Installs Onyx at /opt/onyx/"
echo ""

sudo rm -rf /opt/onyx
sudo mkdir -p /opt/onyx/bin
sudo cp -a /opt/cr-ox/embedded/ /opt/onyx/
sudo cp -a src /opt/onyx/
sudo cp .build/onyx /opt/onyx/embedded/bin/onyx

echo '#!/usr/bin/env bash
INSTALL_DIR="$(dirname $(realpath $(readlink $0 || echo $0)))/.."
export CRYSTAL_PATH=${CRYSTAL_PATH:-"libs:$INSTALL_DIR/src"}
export PATH="$INSTALL_DIR/embedded/bin:$PATH"
export LIBRARY_PATH="$INSTALL_DIR/embedded/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
"$INSTALL_DIR/embedded/bin/onyx" "$@"
' | sudo tee /opt/onyx/bin/onyx > /dev/null

sudo chmod 755 /opt/onyx/bin/onyx
sudo ln -fs /opt/onyx/bin/onyx /usr/local/bin/onyx
