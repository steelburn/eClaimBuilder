#!/bin/bash
L1TARGETFILE=android-release-unsigned.apk
L1SOURCE1=eClaimMobile/platforms/android/build/outputs/apk/release/android-release-unsigned.apk
L1SOURCE2=eClaimMobile/platforms/android/app/build/outputs/apk/release/app-release-unsigned.apk
L1SOURCE3=eClaimMobile/platforms/android/build/outputs/apk/android-release-unsigned.apk

if [[ "$ANDROID_HOME" == "" ]] 
then
    echo "ANDROID_HOME not set. We can't continue."
    exit 1;
elif [[ `which zipalign` == '' ]] 
then
ZIPALIGN=`find $ANDROID_HOME -name "zipalign" | tail -1`
else
    ZIPALIGN=zipalign
fi

echo This script will build and sign APK for release in Google Play Store.

# Create signing key
# Note: Only do this once per application. 
# keytool -genkey -v -keystore my-release-key.keystore -alias <alias_name> -keyalg RSA -keysize 2048 -validity 10000
# keytool -genkey -v -keystore my-release-key.keystore -alias eClaimMobile -keyalg RSA -keysize 2048 -validity 10000

#echo Build unsigned APK
#echo Open another CLI interface and run this manually:
#echo ionic cordova build android --release
#echo Press ENTER once your build process has been completed.
#read

# copy unsigned APK to current directory
if [[ -f $L1SOURCE1 ]]
    then
    # Remove any existing APK in current directory.
    rm *.apk
    cp $L1SOURCE1 $L1TARGETFILE
    echo "$L1TARGETFILE has been copied from $L1SOURCE1"
elif [[ -f $L1SOURCE2 ]]
    then
    # Remove any existing APK in current directory.
    rm *.apk
    cp $L1SOURCE2 $L1TARGETFILE
    echo "$L1TARGETFILE has been copied from $L1SOURCE2"
elif [[ -f $L1SOURCE3 ]]
    then
    # Remove any existing APK in current directory.
    rm *.apk
    cp $L1SOURCE3 $L1TARGETFILE
    echo "$L1TARGETFILE has been copied from $L1SOURCE3"
else
    echo "Unsigned APK file does not exist. Exiting."
    exit -1
    fi

# Sign the APK with out certificate.
echo Signing APK. 
echo Password for keystore: P@ssw0rd@zen
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore my-release-key.keystore android-release-unsigned.apk eClaimMobile

# ZIPalign the signed APK and save as eClaimMobile.apk
# echo If zipalign command is not detected. Try giving full path from sdk tool. 
# echo C:\Users\shabbeer\AppData\Local\Android\Sdk\build-tools\27.0.3\zipalign -v 4 android-release-unsigned.apk eClaimMobile.apk
echo ZIP-aligning using $ZIPALIGN
$ZIPALIGN -v 4 android-release-unsigned.apk eClaimMobile.apk

# Remove old unaligned APK
rm android-release-unsigned.apk

echo APK signing completed. Press ENTER.
read
ls -la *.apk

# Alternatively, you can sign during build, and just use zipalign command
# ionic cordova build android --release -- --keystore="my-release-key.keystore" --storePassword=P@ssw0rd@zen --alias=eClaimMobile
