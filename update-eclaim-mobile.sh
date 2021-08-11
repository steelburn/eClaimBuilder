#!/bin/bash
#Internal parameters:
export ORG_GRADLE_PROJECT_cdvMinSdkVersion=20
export ORG_GRADLE_PROJECT_cdvtargetSdkVersion=28
NODETARGETVER=lts/dubnium

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
    echo -e "         5. Update build environment"
    if [ `uname -s` == Darwin ] 
        then 
        read -p "Enter [0]/1/2/3/5:" option
        else
        read -p "Enter [0]/1/2/5:" option
        fi
    return $option
}

function setup_eclaim() {
    git clone git@github.com:zencomputersystems/eClaimMobile
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
# Debian only
../builder-scripts/prep-android-linux.sh
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

function update_rc_darwin() {
    ANDROID_HOME=/usr/local/share/android-sdk
    CURRENTDIR=`pwd`
    cd $HOME
    echo "
    export ANT_HOME=/usr/local/opt/ant
    export ANT_HOME=/usr/local/opt/ant/libexec
    export MAVEN_HOME=/usr/local/opt/maven
    export GRADLE_HOME=/usr/local/opt/gradle
    export ANDROID_HOME=/usr/local/share/android-sdk
    export ANDROID_SDK_ROOT=/usr/local/share/android-sdk
    export ANDROID_NDK_HOME=/usr/local/share/android-ndk

    export PATH=\$ANT_HOME/bin:\$PATH
    export PATH=\$MAVEN_HOME/bin:\$PATH
    export PATH=\$GRADLE_HOME/bin:\$PATH
    export PATH=\$ANDROID_HOME/tools:\$PATH
    export PATH=\$ANDROID_HOME/platform-tools:\$PATH
    export PATH=\$ANDROID_HOME/build-tools:\$PATH
    export PATH=\$ANDROID_HOME/build-tools/$(ls $ANDROID_HOME/build-tools | sort | tail -1):\$PATH
    " > ~/.androidrc
    if [ $(cat .bashrc | grep 'source ~/.androidrc' | wc -l) == 0 ] ; then 
        echo source ~/.androidrc >> ~/.bashrc
        fi 
    if [ $(cat .zshrc | grep 'source ~/.androidrc' | wc -l) == 0 ] ; then 
        echo source ~/.androidrc >> ~/.zshrc
        fi 
    if [ $(cat .bashrc | grep 'source .bashrc' | wc -l) == 0 ] ; then 
        echo "source .bashrc" >> ~/.bash_profile
        fi 
    cd $CURRENTDIR
}

function update_android_sdk_darwin() {
    sdkmanager --update
    LATEST_BUILDTOOLS="build-tools;$(sdkmanager --list | grep -v '\-rc' | awk '{ print $1 }' | grep -e 'build-tools;' | awk 'BEGIN { FS = ";" } ; { print $2 }' | sort -nr | head -1)"
    LATEST_PLATFORMS="platforms;android-$(sdkmanager --list | awk '{ print $1 }' | grep -e 'platforms;' | awk 'BEGIN { FS = "-" } ; { print $2 }' | sort -nr | head -1)"
    sdkmanager "$LATEST_PLATFORMS" "$LATEST_BUILDTOOLS" "extras;google;m2repository" "extras;android;m2repository"
    yes | sdkmanager --licenses
    update_rc_darwin
}

#WIP:
function install_android_sdk_darwin() {
    brew uninstall java
    brew tap caskroom/versions
    brew install java8
    brew install --cask homebrew/cask-versions/adoptopenjdk8
    mkdir -p ~/.android
    touch ~/.android/repositories.cfg

    brew install ant
    brew install maven
    brew install gradle
    brew install android-sdk
    brew install android-ndk
    sdkmanager --update
    sdkmanager "platforms;android-28" "build-tools;28.0.3" "extras;google;m2repository" "extras;android;m2repository"
    yes | sdkmanager --licenses
    brew install intel-haxm
   
   update_rc_darwin
}

#WIP:
function init() {
    echo "Updating package manager"
    install_brew
    sudo $update_pkg
    sudo $add_pkg curl git build-essential
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
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
            nvm install $NODETARGETVER
            nvm use $NODETARGETVER
            echo "source .bashrc" >> .bash_profile
            echo "source .androidrc" >> .bash_profile
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
    ionic cordova build android --release && \
    echo "Running signing script: $WD/build-signed.sh" && \
    cd $WD && \
    $WD/build-signed.sh
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
            elif [[ $menuoption == '5' ]]
                then
                echo "Updating build environment"
                update_android_sdk_darwin
            else
                exit 0
            fi
        elif [[ $PARAM == 'apk' ]]
            then
            echo "Okay. We'll build APK, sign it, and update a copy in the development server."
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
