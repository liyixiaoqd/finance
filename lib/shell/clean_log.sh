echo "CLEAN LOG START!!! [`date`]"

fin_log_path="/opt/rails-app/epp/log"

log_bak_file="production.log.bak_`date +"%m%d"`"
cd $fin_log_path
cp production.log  $log_bak_file
echo "cp production.log to $log_bak_file end"
echo "log clean! [`date`]" > production.log
echo "clean production.log end"
gzip $log_bak_file
echo "gzip $log_bak_file end"

echo "CLEAN LOG END!!! [`date`]"