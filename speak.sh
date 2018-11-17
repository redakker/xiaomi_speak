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
LANGUAGE=hu-HU #en-GB #And you can use what google allows
VOLUME=15 #1-30

#########################################################################

if [ "$#" -eq  "0" ]
  then
    echo "No arguments supplied, at least one word required"
    exit
fi


for WORD in "$@"
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

miio protocol call ${XIAOMI_GATEWAY_IP} play_music_new [\"5001\",30]
