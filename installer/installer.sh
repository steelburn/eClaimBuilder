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
if [[ ! -d eClaimBuilder ]]; 
then 
 git clone $REPO
else 
 echo "Looks like eClaimBuilder repo folder already exist. We'll skip cloning the repo."
fi

echo "OK. We're done here. Next step: "
echo "  cd eClaimBuilder "
echo "  ./update-eclaim-mobile.sh init"

if [[ ! -f ~/.ssh/id_rsa.pub ]]
then
 echo "Private/public key pair is not available yet. We'll generate one for you."
 ssh-keygen -q
 echo "Key generated. Please add the following ~/.ssh/id_rsa.pub content into your Github account:"
 cat ~/.ssh/id_rsa.pub
 read
else
 echo "Please add ~/.ssh/id_rsa.pub below into your Github SSH and GPG keys:"
 cat ~/.ssh/id_rsa.pub
fi

echo "Installing JDK8."
sudo apt update 
sudo apt install -y software-properties-common
sudo apt-add-repository 'deb http://security.debian.org/debian-security stretch/updates main' 
sudo apt-get update
sudo apt install -y  openjdk-8-jdk
sudo update-alternatives --config java
echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))" > ~/.androidrc
