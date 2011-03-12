#!/bin/sh

cd /home/build/astor2/build
su -c git pull
su -c ./build-docs.sh build
