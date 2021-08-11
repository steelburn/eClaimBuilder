#!/bin/bash

# Prepared Android CLI environment for Debian

# Fetch latest Android CLI Tools from Android Studio website
PLATFORM=linux
ANDROID_SDK_HOME=~/Android/sdk
ANDROID_SDK_ROOT=~/Android/sdk
ANDROID_CMDLINE=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin
ANDROID_PLATFORM_VERSION=31
ANDROID_BUILD_TOOLS_VERSION=28.0.3
ANDROID_HOME=$ANDROID_SDK_HOME

mkdir -p $ANDROID_SDK_HOME 
mkdir -p $ANDROID_SDK_ROOT 

cd $ANDROID_SDK_ROOT
curl -qo- https://developer.android.com/studio | grep commandlinetools-$PLATFORM | grep href | echo wget -c $(sed 's/href\=//g') | sh

for i in $(ls commandlinetools-$PLATFORM-*.zip)
do
    mkdir -p $ANDROID_SDK_ROOT/cmdline-tools
    unzip $i -d $ANDROID_SDK_ROOT/cmdline-tools
    mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest
done
yes | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --licenses
$ANDROID_CMDLINE/sdkmanager --install "build-tools;$ANDROID_BUILD_TOOLS_VERSION" "platforms;android-$ANDROID_PLATFORM_VERSION"


echo "export ANDROID_SDK_HOME=$ANDROID_SDK_HOME" >> ~/.androidrc
echo "export ANDROID_SDK_ROOT=$ANDROID_SDK_HOME" >> ~/.androidrc
echo "export ANDROID_HOME=$ANDROID_SDK_HOME" >> ~/.androidrc
echo "export ANDROID_BUILD_TOOLS_VERSION=$ANDROID_BUILD_TOOLS_VERSION" >> ~/.androidrc
echo "export ANDROID_PLATFORM_VERSION=$ANDROID_PLATFORM_VERSION" >> ~/.androidrc
echo "export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform_tools:$ANDROID_HOME/build-tools:$ANDROID_HOME/build-tools/$(ls $ANDROID_HOME/build-tools | sort | tail -1)" >> ~/.androidrc
