#!/bin/sh

REMOTE_USER=root
REMOTE_HOST=opensan-trac.etegro.local
REMOTE_PATH=/srv

ssh $REMOTE_USER@$REMOTE_HOST mkdir -p $REMOTE_PATH/wiki
scp -r ../wiki/* $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/wiki/
ssh $REMOTE_USER@$REMOTE_HOST "cd $REMOTE_PATH/wiki ; ./insert_all.sh"
