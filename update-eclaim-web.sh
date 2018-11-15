#!/bin/bash

# Internal parameters:
TARGET=10.5.4.12
USERNAME=steelburn

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
     ssh $TARGET$USERNAME@$TARGET mkdir eclaim-`date +%d`
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
