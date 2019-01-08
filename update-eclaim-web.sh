#!/bin/bash

# Internal parameters:
TARGET=10.5.4.12
USERNAME=steelburn
SOURCEREPO=https://github.com/zencomputersystems/eClaim.git


# Read parameter:
PARAM=$1
function menu () {
 echo "No action parameter was set. What do you want to do?"
 echo "         0. Cancel"
 echo "         1. Update 'eclaim-current' branch ( $0 current )"
 echo "         2. Update 'eclaim-stable' branch ( $0 stable )"
 read -p "Enter [0]/1/2:" option
  return $option
}

function build_eclaim () {
    echo "Building eClaim"
    git stash && git pull
    npm run-script build
    if [[ "$?" == "0" ]]
    then
     ssh $USERNAME@$TARGET rm -rf eclaim-`date +%d` 
     ssh $USERNAME@$TARGET mkdir eclaim-`date +%d`
     scp -r www/* $USERNAME@$TARGET:eclaim-`date +%d`
     return 0
    else
    echo "Error building eClaim."
    return -1
    fi
}
function update_current () {
    echo "Updating current branch"
    ssh $USERNAME@$TARGET rm eclaim-current
    ssh $USERNAME@$TARGET ln -sf eclaim-`date +%d` eclaim-current
}
function update_stable () {
    echo "Updating stable branch"
    ssh $USERNAME@$TARGET rm eclaim-stable
    ssh $USERNAME@$TARGET ln -sf eclaim-`date +%d` eclaim-stable
}

function main() {
    WD=`pwd`
    ECLAIMDIR=$WD/eClaim
    if [ ! -d "$ECLAIMDIR" ]
    then
        echo "eClaim directory not found. Please place the script in parent directory of eClaim."
        echo "Otherwise we can fetch from Github an initial copy of eClaim."
        read -p "Do you want to initialize eClaim from Github repository? Enter y/n:" initrepo
        if [ "$initrepo" == "y" ] || [ "$initrepo" == "Y" ]
        then
            git clone $SOURCEREPO
            cd $ECLAIMDIR
            npm install && \
            npm install --save \
            #    ionic-angular@latest \ 
                @ngx-translate/http-loader@latest \
                crypto-js \
                @types/crypto-js \
                chart.js \
                chart.piecelabel.js \
                xlsx \
                file-saver \
                ngx-pagination \
                file-saver \
                @types/file-saver \
                && \
            npm install  --save-dev \
                @angular/tsc-wrapped @ionic/app-scripts@latest && \
            npm install @types/chart.js ng2-charts
            cd $WD
            echo "Please re-run the script."
        else
            echo "Okay."
        fi
        exit -1
    else
    cd $ECLAIMDIR
    fi
    if [[ $PARAM == '' ]]
        then
        menu
        menuoption=$?
        if [[ $menuoption == '1' ]]
            then
            build_eclaim
            if [[ "$?" == "0" ]]
                then
                update_current
            else
                echo "Not updating softlink."
            fi
        elif [[ $menuoption == '2' ]]
            then
            build_eclaim
            if [[ "$?" == "0" ]]
                then
                update_stable
            else
                echo "Not updating softlink."
            fi
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

#Call main function:
main
