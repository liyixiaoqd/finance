#!/bin/bash
project="/home/lyx/workspace/finance"
cd $HOME
. .bash_profile
# rvm use 2.1.1@rails418

cd $project
rake sync_file:third_payment 2>$project"/log/third_payment.log"
echo " ==================== " >> $project"/log/third_payment.log"
rake finance:reconciliation_wechat 2>$project"/log/third_payment.log"