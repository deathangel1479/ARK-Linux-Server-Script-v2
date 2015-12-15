#!/bin/bash

if [ -z $0 ]; then
    CMD=$BASH_SOURCE
else
    CMD=$0
fi

# Script Github Repository
SCRIPT_REPOSITORY_USER="ComputerBaer"
SCRIPT_REPOSITORY_NAME="ARK-Linux-Server-Script-v2"
SCRIPT_REPOSITORY_BRANCH="master"
SCRIPT_REPOSITORY_URL="https://raw.githubusercontent.com/${SCRIPT_REPOSITORY_USER}/${SCRIPT_REPOSITORY_NAME}/${SCRIPT_REPOSITORY_BRANCH}/"

# Other Settings
SCRIPT_UPDATES=true
SCRIPT_LANGUAGE="en"

SCRIPT_FILE_NAME=$(basename $(readlink -fn $CMD))
SCRIPT_BASE_DIR=$(dirname $(readlink -fn $CMD))/
SCRIPT_SCRIPT_DIR="${SCRIPT_BASE_DIR}.script/"
SCRIPT_ACTION_DIR="${SCRIPT_SCRIPT_DIR}actions/"
SCRIPT_LANG_DIR="${SCRIPT_SCRIPT_DIR}languages/"
SCRIPT_TEMP_DIR="${SCRIPT_BASE_DIR}.temp/"
SCRIPT_BACKUP_DIR="${SCRIPT_BASE_DIR}backups/"
SCRIPT_CONFIG="${SCRIPT_BASE_DIR}configuration.ini"
SCRIPT_CONFIG_SAMPLE="${SCRIPT_BASE_DIR}.script/config-samples/configuration-sample.ini"
SCRIPT_PARAMETER=$*

GAME_APPID=376030
GAME_DIR="${SCRIPT_BASE_DIR}game/"
GAME_EXECUTABLE="${GAME_DIR}ShooterGame/Binaries/Linux/ShooterGameServer"
GAME_SAVED_DIR="${GAME_DIR}ShooterGame/Saved/"
GAME_CONFIG1="${GAME_DIR}ShooterGame/Saved/Config/LinuxServer/GameUserSettings.ini"
GAME_CONFIG1_EDIT="${SCRIPT_BASE_DIR}GameUserSettings.ini"
GAME_CONFIG1_SAMPLE="${SCRIPT_BASE_DIR}.script/config-samples/GameUserSettings-sample.ini"
GAME_CONFIG2="${GAME_DIR}ShooterGame/Saved/Config/LinuxServer/Game.ini"
GAME_CONFIG2_EDIT="${SCRIPT_BASE_DIR}Game.ini"
GAME_VERSION_LATEST=0
GAME_VERSION_CURRENT=0
GAME_STOP_WAIT=7

STEAM_CLEAR_CACHE=true
STEAM_UPDATE_BACKGROUND=true
STEAM_CMD_DIR="${SCRIPT_BASE_DIR}steamcmd/"
STEAM_APPS_DIR="${GAME_DIR}steamapps/"
STEAM_CHACHE_DIR="${HOME}/Steam/appcache"

# Some Colors
FG_RED='\e[31m'
FG_GREEN='\e[32m'
FG_YELLOW='\e[33m'
RESET_ALL='\e[0m'

# Some Strings
STR_YES="yes"
STR_NO="no"
STR_YES_OR_NO="Enter '${STR_YES}' or '${STR_NO}'"

STR_UPDATE_DISABLED="Automatic updating is disabled!"
STR_UPDATE_CHECKING="Search for updates ..."
STR_UPDATE_CHECK_FAILED="Search for updates failed!"
STR_UPDATE_UPTODATE="All files are up-to-date."
STR_UPDATE_FOUND="Update found! Install it now ..."
STR_UPDATE_FILE_FAILED="Updating the file '{0}' failed."
STR_UPDATE_MAINFILE="Main script has been updated. Restart script in {0} seconds ..."
STR_UPDATE_ERROR_CONTINUE="Error occurred during the update! Should be tried to continue? ${STR_YES}/${STR_NO}"
STR_UPDATE_SUCCESSFULL="Update completed successfully."

# Case Insensitive String Comparison
shopt -s nocasematch

# UpdateScript Function
function UpdateScript
{
    local CHECKSUMS_FILE="${SCRIPT_TEMP_DIR}checksums"

    if [[ $SCRIPT_UPDATES != true ]]; then
        echo -e "${FG_RED}${STR_UPDATE_DISABLED}${RESET_ALL}"
        return
    fi

    echo -e "${FG_YELLOW}${STR_UPDATE_CHECKING}${RESET_ALL}"

    # Download Checksums
    local Checksums=$(curl -s "${SCRIPT_REPOSITORY_URL}checksums")
    if [[ $Checksums == "Not Found" ]]; then
        echo -e "${FG_RED}${STR_UPDATE_CHECK_FAILED}${RESET_ALL}"
        return
    fi
    echo "$Checksums" > $CHECKSUMS_FILE

    # Compare Checksums
    local CheckResult=$(md5sum -c $CHECKSUMS_FILE --quiet 2> /dev/null)
    if [[ $CheckResult == "" ]]; then
        echo -e "${FG_GREEN}${STR_UPDATE_UPTODATE}${RESET_ALL}"
        return
    fi

    echo -e "${FG_YELLOW}${STR_UPDATE_FOUND}${RESET_ALL}"

    # Update Files
    local error=false
    local selfUpdated=false
    while IFS=':' read -ra LINE; do
        local FileContent=$(curl -s "${SCRIPT_REPOSITORY_URL}${LINE[0]}")
        if [[ $FileContent == "Not Found" ]]; then
            echo -e "${FG_RED}${STR_UPDATE_FILE_FAILED/'{0}'/${LINE[0]}}${RESET_ALL}"
            error=true
        else
            local dir=$(dirname "${LINE[0]}")
            local file=$(basename "${LINE[0]}")
            if [ ! -d $dir ]; then
                mkdir -p $dir
            fi
            echo "$FileContent" > "${LINE[0]}"

            if [[ $dir == "." ]] && [[ ${file##*.} == "sh" ]]; then
                chmod +x "${LINE[0]}"
            fi

            if [[ $file == $SCRIPT_FILE_NAME ]]; then
                selfUpdated=true
            fi
        fi
    done <<< "$CheckResult"

    # Main Script was updated
    if [[ $selfUpdated == true ]]; then
        echo -e "${FG_YELLOW}${STR_UPDATE_MAINFILE/'{0}'/5}${RESET_ALL}"
        sleep 5s
        $CMD $SCRIPT_PARAMETER
        exit 0
    fi

    # Error while updating
    if [[ $error == true ]]; then
        echo -e "${FG_YELLOW}${STR_UPDATE_ERROR_CONTINUE}${RESET_ALL}"
        while [[ $input != $STR_YES ]]; do
            read input
            if [[ $input == $STR_NO ]]; then
                ExitScript
            elif [[ $input != $STR_YES ]]; then
                echo -e "${FG_YELLOW}${STR_YES_OR_NO}${RESET_ALL}"
            fi
        done
    else
        echo -e "${FG_GREEN}${STR_UPDATE_SUCCESSFULL}${RESET_ALL}"
    fi
}

# CheckBoolean Function
# Param1 - Value to check
# Param2 - Default, if value is invalid
function CheckBoolean
{
    local bool=$1
    local default=$2

    if [[ $bool == true ]] || [[ $bool == false ]]; then
        # Is valid Boolean
        echo ${bool,,}
    else
        # Is invalid Boolean
        echo ${default,,}
    fi
}

# ScriptConfiguration Function
function ScriptConfiguration
{
    if [ ! -f $SCRIPT_CONFIG_SAMPLE ]; then
        return
    fi
    source $SCRIPT_CONFIG_SAMPLE

    if [ ! -f $SCRIPT_CONFIG ]; then
        local CONFIG_DIR=$(dirname $SCRIPT_CONFIG)

        if [ ! -d $CONFIG_DIR ]; then
            mkdir -p $CONFIG_DIR
        fi

        cp $SCRIPT_CONFIG_SAMPLE $SCRIPT_CONFIG
    fi
    source $SCRIPT_CONFIG

    # Load Script Settings
    if [ ! -z $ScriptBranch ]; then
        SCRIPT_REPOSITORY_BRANCH=$ScriptBranch
    fi
    SCRIPT_UPDATES=$(CheckBoolean $ScriptUpdates true)
    if [ ! -z $ScriptLanguage ]; then
        SCRIPT_LANGUAGE=$ScriptLanguage
    fi
}

# ScriptLanguage Function
# Param1 - Missing Language is Error, 0/1
function ScriptLanguage
{
    local LANGUAGE_FILE="${SCRIPT_LANG_DIR}${SCRIPT_LANGUAGE}.lang"
    if [ -f $LANGUAGE_FILE ]; then
        source $LANGUAGE_FILE
    elif [ $1 -eq 1 ]; then
        # String in language file not required
        echo -e "${FG_RED}Language '${SCRIPT_LANGUAGE}' not found. Script execution is canceled.${RESET_ALL}"
        ExitScript
    fi
}

# LoadScripts Function
function LoadScripts
{
    for file in $SCRIPT_SCRIPT_DIR*; do
        if [ -f $file ]; then
            source $file
        fi
    done
}

# InitScript Function
function InitScript
{
    clear

    if [ ! -d $SCRIPT_TEMP_DIR ]; then
        mkdir -p $SCRIPT_TEMP_DIR
    fi

    # Load Configuration and Language
    ScriptConfiguration
    ScriptLanguage 0

    # Update Script
    UpdateScript
    # Reload Configuration and Language
    ScriptConfiguration
    ScriptLanguage 1

    # Is root user
    if [[ $(whoami) == "root" ]]; then
        echo -e "${FG_RED}${STR_ROOT}${RESET_ALL}"
    fi

    # Load all Scripts
    LoadScripts

    # Generate Game Configuration (.script/game.sh)
    CheckGameConfig
}

# RunAction Function
# Param1 - Name of the Action
function RunAction
{
    local name=$1
    if [ -z $name ]; then
        return
    fi

    local ACTION_FILE="${SCRIPT_ACTION_DIR}${name}.sh"
    if [ -f $ACTION_FILE ]; then
        source $ACTION_FILE
    else
        echo -e "${FG_RED}${STR_ACTION_UNKNOWN/'{0}'/$name}${RESET_ALL}"
    fi
}

# CleanUp Function
function CleanUp
{
    rm -r -f $SCRIPT_TEMP_DIR
}

# ExitScript Function
function ExitScript
{
    CleanUp
    exit 0
}

# Run Main Functions
InitScript
RunAction $1
ExitScript
