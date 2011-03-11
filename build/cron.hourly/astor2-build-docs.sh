#!/bin/sh

cd /home/build/astor2/build
git pull
su -c ./build-docs.sh build
