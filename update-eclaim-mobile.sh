#!/bin/bash
#Internal parameters:
TARGET=10.5.4.12
USERNAME=steelburn
APKDEVDIR=~/eclaim-apk

#Read parameter:
PARAM=$1
PARAM2=$2

#Fancy thing:
# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37
# No colour    0;0

RED='\033[0;31m'
NC='\033[0m'
HL='\033[1;33m'
HL2='\033[0;36m'

# Let's come out clean on the supported environment.
# We'll just support MacOS, Debian & Alpine for the time being
function check_platform() {
    if [ `uname -s` == Darwin ] 
        then
        DISTRO=Darwin
        PLATFORM=Darwin
        PLATFORM_SUPPORT=y
        echo "Hello Darwin."
        PYTHON27PKG=python@2
    elif [ `uname -s` == Linux ] 
        then
        PLATFORM=Linux
        DISTRO=`cat /etc/*release | grep ^ID= | cut -d'=' -f2`
        if [ $DISTRO == alpine ] 
            then
            PLATFORM_SUPPORT=y
            update_pkg='apk update'
            add_pkg='apk add'
            del_pkg='apk del'
            # Python 2.7 package:
            PYTHON27PKG=python2

        elif [ $DISTRO == debian ] || [ $DISTRO == ubuntu ]
            then
            PLATFORM_SUPPORT=y
            update_pkg='apt-get update'
            add_pkg='apt-get install -y'
            del_pkg='apt-get autoremove -y'
            clean_pkg='rm '
            PYTHON27PKG=python2.7
        else 
        PLATFORM_SUPPORT=n
        echo -e "${RED}Sorry.${NC} We don't support this platform yet."
        exit 1        
        fi
    else
        PLATFORM_SUPPORT=n
        echo -e "${RED}Sorry.${NC} We don't support this platform yet."
        exit 1
    fi
}

function menu () {
    echo "No action parameter was set. What do you want to do?"
    echo -e "         0. Cancel"
    echo -e "         1. Initialize build environment ${HL2}( $0 init )${NC}"
    echo -e "         2. Build & update 'eclaim-apk' in development ${HL2}( $0 apk )${NC}"
    if [ `uname -s` == Darwin ] 
        then 
        echo -e "         3. Build & update 'eclaim-ios' ${HL2}( $0 ios )${NC}" 
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
    npm rebuild node-sass
}

# WIP, mostly done but needs to evaluate with full run.
function install_android_sdk_linux() {
    # installation script for Android SDK and JDK 8 on Ubuntu 
    # for Android development with gradlew-based projects
    # tested on Cloud9
    CURRENTDIR=`pwd`
    ANDROID_HOME=$HOME/lib/android-sdk-linux
    ANDROID_SDK_VERSION=24.4.1
    ANDROID_BUILD_TOOLS_VERSION=23.0.2
    ANDROID_API_LEVEL=22

    mkdir -p $HOME/lib
    cd $HOME/lib
    wget http://dl.google.com/android/android-sdk_r${ANDROID_SDK_VERSION}-linux.tgz
    tar -zxf android-sdk_r${ANDROID_SDK_VERSION}-linux.tgz
    echo yes | ${ANDROID_HOME}/tools/android update sdk --filter tools,platform-tools,build-tools-${ANDROID_BUILD_TOOLS_VERSION},android-${ANDROID_API_LEVEL},extra-android-support,extra-android-m2repository,extra-google-m2repository --no-ui --force --no-https --all > /dev/null
    rm $HOME/lib/android-sdk_r${ANDROID_SDK_VERSION}-linux.tgz

    if [ $DISTRO == debian ] || [ $DISTRO == ubuntu ]
        then
            sudo add-apt-repository ppa:webupd8team/java
            sudo $update_pkg
            sudo $add_pkg -qq lib32stdc++6 lib32z1 # Android SDK dependencies
            sudo $add_pkg oracle-java8-installer
    elif [ $DISTRO == alpine ]
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
    cd $CURRENTDIR
}

function install_brew() {
    if [ `uname -s` == Darwin ] 
        then
        BREW=`command -v brew`
        echo "BREW is in $BREW"
        if [ ! -f "/usr/local/bin/brew" ]
            then
            echo -e "${HL}brew${NC} package manager is not installed. I need brew to function properly."
            #Get brew
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
            else
            echo -e "We have ${HL}brew${NC}. That's good."
            fi
        update_pkg='brew update'
        add_pkg='brew install'
        del_pkg='brew uninstall'
    fi
}

#WIP:
function install_android_sdk_darwin() {
    brew cask uninstall java
    brew tap caskroom/versions
    brew cask install java8
    mkdir -p ~/.android
    touch ~/.android/repositories.cfg

    brew install ant
    brew install maven
    brew install gradle
    brew cask install android-sdk
    brew cask install android-ndk
    sdkmanager --update
    sdkmanager "platforms;android-25" "build-tools;25.0.2" "extras;google;m2repository" "extras;android;m2repository"
    yes | sdkmanager --licenses
    brew cask install intel-haxm
   
   echo "
    export ANT_HOME=/usr/local/opt/ant
    export ANT_HOME=/usr/local/opt/ant/libexec
    export MAVEN_HOME=/usr/local/opt/maven
    export GRADLE_HOME=/usr/local/opt/gradle
    export ANDROID_HOME=/usr/local/share/android-sdk
    export ANDROID_SDK_ROOT=/usr/local/share/android-sdk
    export ANDROID_NDK_HOME=/usr/local/share/android-ndk

    export PATH=$ANT_HOME/bin:$PATH
    export PATH=$MAVEN_HOME/bin:$PATH
    export PATH=$GRADLE_HOME/bin:$PATH
    export PATH=$ANDROID_HOME/tools:$PATH
    export PATH=$ANDROID_HOME/platform-tools:$PATH
    export PATH=$ANDROID_HOME/build-tools/export PATH=$ANDROID_HOME/build-tools/$(ls $ANDROID_HOME/build-tools | sort | tail -1):$PATH
    " > ~/.androidrc
    echo source ~/.androidrc >> ~./.bashrc
    echo source .bashrc >> ~/.bash_profile
}

#WIP:
function init() {
    echo "Updating package manager"
    install_brew
    sudo $update_pkg
    sudo $add_pkg curl
    echo "Initializing build environment"
    # Install Python
    sudo $add_pkg $PYTHON27PKG
    # Install NodeJS
    # Don't install NodeJS if we already have the right version
    NODEACCEPTED=n
    NPMACCEPTED=n
    NODE_INSTALLED=`command -v node`
    if [ ! -z $NODE_INSTALLED ]
        then
        NODEVER=`node -v`
        if [ "`echo $NODEVER | cut -d'.' -f1`" == "v8" ] 
            then
            NODEACCEPTED=y
            else
            NODEACCEPTED=n
            fi
        fi
    NPM_INSTALLED=`command -v npm`
    if [ ! -z $NPM_INSTALLED ]
        then        
        NPMVER=`npm -v`
        if [ "`echo $NPMVER | cut -d'.' -f1`" == "v4" ]
            then
            NPMACCEPTED=y
            else
            NPMACCEPTED=n
            fi
        fi
    if [ "$NODEACCEPTED" == "n" ] && [ "$NPMACCEPTED" == "n" ]
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
    if [ "$PLATFORM" == "Linux" ]
        then
        install_android_sdk_linux
    elif [ "$PLATFORM" == "Darwin" ]
        then
        install_android_sdk_darwin
        fi

}

function build_eclaim_apk() {
    ionic cordova build android --release && $WD/build-signed.sh && scp *.apk $USERNAME@$TARGET:$APKDEVDIR
}

function build_eclaim_ios() {
    ionic cordova build ios --release
}

function main() {
    WD=`pwd`
    ECLAIMDIR=$WD/eClaimMobile
    check_platform
    if [[ $PLATFORM_SUPPORT == y ]]
        then
        if [ ! -d "$ECLAIMDIR" ]
        then
            if [ "$PARAM" == "init" ]
            then
                echo "eClaimMobile directory not found. So we will include preparing eCaimMobile as part of"
                echo "initialization process."
                init
                setup_eclaim
                echo "Initialization & setup completed. Please restart your terminal session."
                exit 0
            else
                echo "eClaimMobile directory not found. We can fetch and configure eClaimMobile for you."
                echo "Otherwise, please run the script in parent directory of eClaimMobile."
                read -p " Do you want me to fetch and configure eClaimMobile for you? (y for yes; any other key to exit: " yesplease
                if [ "$yesplease" == "y" ] || [ "$yesplease" == "Y" ]
                    then
                    init
                    setup_eclaim
                echo "Initialization & setup completed. Please restart your terminal session."
                    exit 0
                else
                    exit -1
                fi
            fi
        else
            cd $ECLAIMDIR
        fi
        if [[ "$PARAM" == "" ]]
            then
            menu
            menuoption=$?
            if [[ $menuoption == '1' ]]
                then
                echo "Initialize build environment ( $0 init )"
                init
                echo "Initialization & setup completed. Please restart your terminal session."
            elif [[ $menuoption == '2' ]]
                then
                echo "Build & update 'eclaim-apk' in development ( $0 apk )"
                build_eclaim_apk
                if [[ "$?" == "0" ]]
                    then
                    update_stable
                else
                    echo "Not updating softlink."
                fi
            elif [[ $menuoption == '3' ]]
                then
                echo "Build & update 'eclaim-ios' ( $0 ios )"
                build_eclaim_ios
            else
                exit 0
            fi
        elif [[ $PARAM == 'apk' ]]
            then
            echo "Okay. We'll build APK, signed it, and update a copy in the development server."
            build_eclaim_apk
        elif [[ $PARAM == 'ios' ]]
            then 
            echo "Okay. We'll build iOS."
            build_eclaim_ios
        elif [ "$PARAM" == "init" ]
            then
            init
                echo "Initialization & setup completed. Please restart your terminal session."
        else
            echo "You have entered '$PARAM' as parameter. I don't understand that."
        fi
        cd $HOME
        source .bashrc
        cd $WD
    fi

}

# Run main function
main
