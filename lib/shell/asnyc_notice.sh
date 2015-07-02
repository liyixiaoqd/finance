#!/bin/bash
project="/home/lyx/workspace/finance"
cd $HOME
. .bash_profile
cd $project
rake async_notice:online_pay 2>$project"/log/async_notice.log"
