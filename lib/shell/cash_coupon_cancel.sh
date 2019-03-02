#!/bin/bash
project="/home/lyx/workspace/finance"
cd $HOME
. .bash_profile
cd $project
rake callqueue:cash_coupon_cancel 2>$project"/log/cron_callqueue.log"