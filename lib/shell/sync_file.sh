#!/bin/bash
project="/home/lyx/workspace/finance"
cd $HOME
. .bash_profile
cd $project
rake sync_file:product[$1] 2>$project"/log/cron_sync_file.log"
