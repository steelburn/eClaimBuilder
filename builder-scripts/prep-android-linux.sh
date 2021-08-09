#!/bin/bash

# Prepared Android CLI environment for Debian

# Fetch latest Android CLI Tools from Android Studio website
PLATFORM=linux
ANDROID_SDK_HOME=~/Android/sdk
ANDROID_SDK_ROOT=~/Android/sdk
ANDROID_CMDLINE=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin
ANDROID_PLATFORM_VERSION=31
ANDROID_BUILD_TOOLS_VERSION=28.0.3
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


echo "ANDROID_SDK_HOME=$ANDROID_SDK_HOME" >> ~/.androidrc
echo "ANDROID_SDK_ROOT=$ANDROID_SDK_HOME" >> ~/.androidrc
