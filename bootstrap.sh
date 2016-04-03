#!/usr/bin/env bash

echo "Checks for required utils"

which wget || echo "Sorry mate - you need to install 'wget' to continue. Use your package-manager and get it."
which wget || exit 1

which git || echo "Sorry mate - you need to install 'git' to continue. Use your package-manager and get it."
which git || exit 1


onyx_repo=`pwd`

cd
mkdir -p tmp
cd tmp

echo ""
echo "If shit happens - create an issue at https://github.com/ozra/onyx-lang/issues (first make sure it's not already reported!)"
echo ""

echo "Let's sudo you first, so that's done:"
sudo mkdir -p /opt



CRYSTAL_VERSION="0.15.0"

echo "Gets Crystal Version '${CRYSTAL_VERSION}'"

# curl can't handle the redirect to data-store!
wget "https://github.com/manastech/crystal/releases/download/${CRYSTAL_VERSION}/crystal-${CRYSTAL_VERSION}-1-linux-x86_64.tar.gz" -O - | tar zx
echo "Installs Crystal ${CRYSTAL_VERSION} at /opt/cr-ox/"

sudo mkdir -p /opt
sudo rm -rf /opt/cr-ox
sudo cp -a "crystal-${CRYSTAL_VERSION}-1/" /opt/cr-ox
sudo mv /opt/cr-ox/bin/crystal /opt/cr-ox/bin/cr-ox
sudo ln -fs /opt/cr-ox/bin/cr-ox /usr/local/bin/cr-ox

rm -rf "crystal-${CRYSTAL_VERSION}-1"


# echo "Get Onyx latest"

# git clone --depth 1 --branch master https://github.com/ozra/onyx-lang
# cd onyx-lang

cd $onyx_repo

echo ""
echo "Compiles Onyx compiler in release mode."
echo "This may take a while - meanwhile you have some options:"
echo ""
echo "  - stretch your legs and grab a coffee."
echo "  - or a cigar."
echo "  - or perhaps tea?"
echo "  - I see... you prefer beer?"
echo "  - Or do yoga"
echo "  - Or ninja moves! - same same but cooler name!"
echo "  - whatever makes your clock tick (literally)"
echo ""

# LIBRARY_PATH="/opt/crystal/embedded/lib/;$LIBRARY_PATH"
# CRYSTAL_CONFIG_PATH=`pwd`/src crystal build --release --link-flags "-L/opt/crystal/embedded/lib" -o .build/onyx src/compiler/onyx.cr
CRYSTAL_CONFIG_PATH=`pwd`/src ./bin/cr-ox build --release -o .build/onyx src/compiler/onyx.cr

echo "Installs Onyx at /opt/onyx/"
echo ""

sudo rm -rf /opt/onyx
sudo mkdir -p /opt/onyx/bin
sudo cp -a /opt/cr-ox/embedded/ /opt/onyx/
sudo cp -a src /opt/onyx/
sudo cp .build/onyx /opt/onyx/embedded/bin/onyx

echo '#!/usr/bin/env bash
INSTALL_DIR="$(dirname $(readlink $0 || echo $0))/.."
export CRYSTAL_PATH=${CRYSTAL_PATH:-"libs:$INSTALL_DIR/src"}
export PATH="$INSTALL_DIR/embedded/bin:$PATH"
export LIBRARY_PATH="$INSTALL_DIR/embedded/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"
"$INSTALL_DIR/embedded/bin/onyx" "$@"
' | sudo tee /opt/onyx/bin/onyx > /dev/null

sudo chmod 755 /opt/onyx/bin/onyx
sudo ln -fs /opt/onyx/bin/onyx /usr/local/bin/onyx

echo "All done! Enjoy, and don't let the beta-bugs bite!"
echo ""
