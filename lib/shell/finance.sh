#!/bin/bash
project="/home/lyx/workspace/finance"
cd $HOME
. .bash_profile
cd $project
rake finance:reconciliation 2>$project"/log/cron_finance.log"
