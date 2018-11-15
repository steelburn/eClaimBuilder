#!/bin/bash

#Internal parameters:
TARGET=10.5.4.12
USERNAME=steelburn

#Read parameter:
PARAM=$1
PARAM2=$2

# Let's come out clean on the supported environment.
# We'll just support MacOS, Debian & Alpine for the time being
function check_platform() {
    if [ `uname -s` == Darwin ] 
        then
        DISTRO=Darwin
        PLATFORM=Darwin
        PLATFORM_SUPPORT=y
        echo "Hello Darwin."
        BREW=`which brew`
        if [ '$BREW' == '' ]
            then
            echo "'brew' package manager is not installed. I need brew to function properly."
            #Get brew
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
            else
            echo "We have 'brew'. That's good."
            fi
        update_pkg='brew update'
        add_pkg='brew install'
        del_pkg='brew uninstall'
        PYTHON27PKG=python@2

    elif [ `uname -s` == Linux ] 
        then
        PLATFORM=Linux
        DISTRO=`cat /etc/*release | grep ^ID= | cut -d'=' -f2`
        if [ DISTRO == alpine ] 
            then
            PLATFORM_SUPPORT=y
            update_pkg='apk update'
            add_pkg='apk add'
            del_pkg='apk del'
            # Python 2.7 package:
            PYTHON27PKG=python2

        elif [ DISTRO == debian ] 
            then
            PLATFORM_SUPPORT=y
            update_pkg='apt-get update'
            add_pkg='apt-get install -y'
            del_pkg='apt-get autoremove -y'
            clean_pkg='rm '
            PYTHON27PKG=python2.7
        fi
    else
        PLATFORM_SUPPORT=n
        echo "Sorry. We don't support this platform yet."
        exit -1
    fi
}

function menu () {
    echo "No action parameter was set. What do you want to do?"
    echo "         0. Cancel"
    echo "         1. Initialize build environment ( $0 init )"
    echo "         2. Build & update 'eclaim-apk' in development ( $0 apk )"
    if [ `uname -s` == Darwin ] 
        then 
        echo "         3. Build & update 'eclaim-ios' ( $0 ios )" 
        fi
    if [ `uname -s` == Darwin ] 
        then 
        read -p "Enter [0]/1/2/3:" option
        else
        read -p "Enter [0]/1/2:" option
        fi
    return $option
}

function setup_eclaim() {
    git clone https://github.com/zencomputersystems/eClaimMobile.git
    cd $ECLAIMDIR
    npm install
    npm install --save \
        angular2-uuid \
        @ionic-native/transfer \
        @ionic-native/camera \
        @ionic-native/file \
        @ionic-native/file-path \
        @ngx-translate/core \
        @ngx-translate/http-loader@latest \
        crypto-js \
        @types/crypto-js \
        @types/chart.js \
        ng2-charts \
        chart.js \
        chart.piecelabel.js \
        @ionic-native/network \
        @ionic-native/app-version \
        @ionic-native/market
    ionic cordova platform add android --save
    if [ $PLATFORM == Darwin ] 
        then
        ionic cordova platform add ios --save
        fi
    ionic cordova plugin add \
        cordova-plugin-file-transfer \
        cordova-plugin-camera \
        cordova-plugin-file \
        cordova-plugin-filepath \
        cordova-plugin-network-information \
        cordova-plugin-app-version \
        cordova-plugin-market \
        --save
    npm rebuild node-sass --force
}

# WIP, mostly done but needs to evaluate with full run.
function install_android_sdk_linux() {
    # installation script for Android SDK and JDK 8 on Ubuntu 
    # for Android development with gradlew-based projects
    # tested on Cloud9

    ANDROID_HOME=$HOME/lib/android-sdk-linux
    ANDROID_SDK_VERSION=24.4.1
    ANDROID_BUILD_TOOLS_VERSION=23.0.2
    ANDROID_API_LEVEL=22

    cd $HOME/lib
    wget http://dl.google.com/android/android-sdk_r${ANDROID_SDK_VERSION}-linux.tgz
    tar -zxf android-sdk_r${ANDROID_SDK_VERSION}.tgz
    echo yes | ${ANDROID_HOME}/tools/android update sdk --filter tools,platform-tools,build-tools-${ANDROID_BUILD_TOOLS_VERSION},android-${ANDROID_API_LEVEL},extra-android-support,extra-android-m2repository,extra-google-m2repository --no-ui --force --no-https --all > /dev/null
    rm $HOME/lib/android-sdk_r${ANDROID_SDK_VERSION}-linux.tgz

    if [ DISTRO == debian ]
        then
            sudo $add_pkg ppa:webupd8team/java
            sudo $update_pkg
            sudo $add_pkg -qq lib32stdc++6 lib32z1 # Android SDK dependencies
            sudo $add_pkg oracle-java8-installer
    elif [ DISTRO == alpine ]
        then
            $update_pkg
            $add_pkg openjdk7 
            cd /opt
            wget -q ${ANDROID_SDK_URL} && \
            tar -xzf ${ANDROID_SDK_FILENAME} && \
            rm ${ANDROID_SDK_FILENAME} && \
            echo y | android update sdk --no-ui -a --filter tools,platform-tools,${ANDROID_API_LEVELS},build-tools-${ANDROID_BUILD_TOOLS_VERSION} --no-https && \
            rm /var/cache/apk/*
        fi
}

#WIP:
function install_android_sdk_darwin() {
    #We do nothing now. We'll have the SDK installation steps ready soon.
    echo "We are doing nothing now."
}

#WIP:
function init() {
    check_platform
    echo "Updating package manager"
    $update_pkg
    echo "Initializing build environment"
    # Install Python
    $add_pkg $PYTHON27PKG
    # Install NodeJS
    # Don't install NodeJS if we already have the right version
    NODEVER=`node -v`
    if [ `echo $NODEVER | cut -d'.' -f1` == v8 ] 
        then
        NODEACCEPTED=y
        else
        NODEACCEPTED=n
        fi
    NPMVER=`npm -v`
    if [ `echo $NPMVER | cut -d'.' -f1` == v4 ]
        then
        NPMACCEPTED=y
        else
        NPMACCEPTED=n
        fi
    if [ NODEACCEPTED == n ] && [ NPMACCEPTED == n ]
        then
            touch ~/.bash_profile
            touch ~/.bashrc
            curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
            nvm install lts/carbon
            nvm use lts/carbon
        else
            echo "You already have NodeJS $NODEVER and NPM $NPMVER. We'll skip NodeJS installation."
        fi
    # Install Cordova & Ionic
    npm i -g ionic cordova
    if [ $PLATFORM == Linux ]
        then
        install_android_sdk_linux
    elif [ $PLATFORM == Darwin ]
        then
        install_android_sdk_darwin
        fi
}

function main() {
    WD=`pwd`
    ECLAIMDIR=$WD/eClaimMobile
    check_platform
    if [ ! -d "$ECLAIMDIR" ]
    then
        if [ "$PARAM" == "init" ]
        then
            echo "eClaimMobile directory not found. So we will include preparing eCaimMobile as part of"
            echo "initialization process."
            init
            setup_eclaim
            exit 0
        else
            echo "eClaimMobile directory not found. We can fetch and configure eClaimMobile for you."
            echo "Otherwise, please run the script in parent directory of eClaimMobile."
            read -" Do you want me to fetch and configure eClaimMobile for you? (y for yes; any other key to exit: " yesplease
            if [ $yesplease == 'y' ] || [ $yesplease == 'Y' ]
                then
                setup_eclaim
                exit 0
            else
                exit -1
            fi
        fi
    else
        cd $ECLAIMDIR
    fi
    if [[ $PARAM == '' ]]
        then
        menu
        menuoption=$?
        if [[ $menuoption == '1' ]]
            then
            echo "Initialize build environment ( $0 init )"
            init
        elif [[ $menuoption == '2' ]]
            then
            echo "Build & update 'eclaim-apk' in development ( $0 apk )"
            build_eclaim
            if [[ "$?" == "0" ]]
                then
                update_stable
            else
                echo "Not updating softlink."
            fi
        elif [[ $menuoption == '3' ]]
            then
            echo "Build & update 'eclaim-ios' ( $0 ios )"
        else
            exit 0
        fi
    elif [[ $PARAM == 'current' ]]
        then
        echo "Okay. We'll build current."
        build_eclaim
        update_current
    elif [[ $PARAM == 'stable' ]]
        then 
        echo "Okay. We'll build stable."
        build_eclaim
        update_stable
    else
        echo "You have entered '$1' as parameter. I don't understand that."
    fi
    cd $WD
}

# Run main function
main