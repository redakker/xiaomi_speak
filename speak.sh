#!/bin/bash

# This script triggers to Speak Xiaomi gateway
# To run, need to install miio script, ffmpeg, npm and node and a webserver
# It uses google tts to generate a sound file from text
# 1. ffmpeg downloads the the given text as tts sound from google
# 2. miio uploads this file to this a webserver (currently here to raspberry webserver)
# 3. miio triggers Xiaomi gateway to play that sound

# Basic documentation of the miio command
# https://github.com/aholstenson/miio

# You need to set up miio first (need just once in one system) using the token
# To get the Xiaomi gateway token: go to the Mi Home app, open gateway, tap to top right ... menu, about, Hub info. The Json data should contain the token

# TODO: Xiaomi gateway can store more sounds. Make it possible to upload a static sound and play that first
# in this way the tts sound not so frightening


## Config ###############################################################

# Webserver should be accessable by gateway
WEBSERVER_HTTP_ADDRESS=http://192.168.1.10:80/
# Xiaomi gateway IP address on a local network
XIAOMI_GATEWAY_IP=192.168.1.35
LOCAL_WEBSERVER_FOLDER=/var/www/
FILENAME=tts.aac
LANGUAGE=en-GB #en-GB #And you can use what google allows
VOLUME=15 #1-30

##!!!!!!!!!!!!!!!!!!!! if you want to use notification sound, please upload it first and just once. Script will use it later.
##!!!!!!!!!!!!!!!!!!!! you can change the notification sound in same way

# miio protocol call ${XIAOMI_GATEWAY_IP} download_user_music [\"5002\",\"${WEBSERVER_HTTP_ADDRESS}${FILENAME}\"]
# Example: miio protocol call 192.168.1.35 download_user_music [\"5002\",\"http://192.168.1.10\notification.aac\"]

#########################################################################

if [ "$#" -eq  "0" ]
  then
    echo "No arguments supplied, at least one word required with -t option. Example speak.sh -t \"this is the one\""
    echo "-v --volume volume of the sound [1-30] default 15"
    echo "-t --text text which will be converted to soundfile using tts [maxumum 50 characters]"
    echo "-n --notification notification before the text [if set then true] default false"
    echo "-l --language lang code [en-GB, hu-HU etc.] Currently google is the tts converter, chech the languages there. Default: en-GB"
    exit
fi


POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -v|--volume)
    VOLUME="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--text)
    TEXT="$2"
    shift # past argument
    shift # past value
    ;;
    -n|--notification)
    NOTIFICATION=true
    shift # past argument
    ;;
    -l|--language)
    LANGUAGE="$2"
    shift # past argument
    shift # past value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
#set -- "${POSITIONAL[@]}" # restore positional parameters

if  [ -z "${TEXT}" ]; then
    echo "Text is required, it must be added. Example speak.sh -t \"this is the one\""
    exit 0
fi

for WORD in ${TEXT}
    do
	SENTENCE="${SENTENCE}+${WORD}"
    done

# Remove the + from the beggining
SENTENCE=${SENTENCE:1}
#echo $SENTENCE
#exit 0;

## ffmpeg drops a TLS error message, but it works :)
ffmpeg -y -i "https://translate.google.com/translate_tts?ie=UTF-8&tl=${LANGUAGE}&client=tw-ob&q=${SENTENCE}" -b:a 64k "${LOCAL_WEBSERVER_FOLDER}${FILENAME}"

miio protocol call ${XIAOMI_GATEWAY_IP} download_user_music [\"5001\",\"${WEBSERVER_HTTP_ADDRESS}${FILENAME}\"]

if [ "$NOTIFICATION" = true ] ; then
    #miio protocol call ${XIAOMI_GATEWAY_IP} download_user_music [\"5002\",\"${WEBSERVER_HTTP_ADDRESS}notification.aac\"]
    miio protocol call ${XIAOMI_GATEWAY_IP} play_music_new [\"5002\",$((VOLUME+3))]
fi

miio protocol call ${XIAOMI_GATEWAY_IP} play_music_new [\"5001\",${VOLUME}]
