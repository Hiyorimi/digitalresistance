while :
do
	echo "Time: `date +%H:%M`";
	sh download.sh
	ruby check_our_ips.rb
	echo "...sleep...";
	sleep 3600
done