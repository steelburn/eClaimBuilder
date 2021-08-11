#!/bin/bash
REPO=https://github.com/steelburn/eClaimBuilder.git

echo "Thanks for downloading. We'll now prepare this host for building Ionic-based eClaimMobile."
CUSER=$(whoami)

if  [[ "$(which sudo)" == "" ]]
then
 echo "sudo is not installed yet. We'll proceed with installing sudo package and add current user as a sudoer."
 su - root -c "apt install -y sudo && echo '$CUSER     ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"
fi

echo "Now we'll prepare some preliminary environment to download the rest of the script."
sudo apt install -y git curl build-essential

echo "Now downloading git repo..."
git clone $REPO

echo "OK. We're done here. Next step: "
echo "  cd eClaimBuilder "
echo "  ./update-eclaim-mobile.sh init"
