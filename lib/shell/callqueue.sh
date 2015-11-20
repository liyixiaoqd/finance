#!/bin/bash
project="/home/lyx/workspace/finance"
cd $HOME
. .bash_profile
cd $project
rake callqueue:online_pay_is_succ 2>$project"/log/cron_callqueue.log"