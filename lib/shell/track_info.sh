#!/bin/bash
project="/home/lyx/workspace/finance"
cd $HOME
. .bash_profile
cd $project
rake callqueue:track_info_proc 2>>$project"/log/track_info_proc.log"