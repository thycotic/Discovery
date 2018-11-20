#!/bin/bash
homes=$(grep oracle /etc/oratab | awk -F":" '{print $2}' | uniq)

for i in $homes
do
if [ -r "$i/network/admin/listener.ora" ] 
then
    #port=$(grep "PORT" $i/network/admin/listener.ora | awk -F= '/=/{print $5}' | sed 's/)//g')
    #dbname=$(grep "GLOBAL_DBNAME" $i/network/admin/listener.ora | awk -F= '/=/{print $5}' | sed 's/)//g')
    #echo "$port\t$dbname"
    rm oracleinfo.txt
    grep -E '(PORT|GLOBAL_DBNAME)' $i/network/admin/listener.ora | sed 's/[)(]//g' | awk '{if($1=="ADDRESS"){port=$9; dbname="";} else if($1=="GLOBAL_DBNAME") dbname=$3; if(dbname!="") print port, dbname;}' >> oracleinfo.txt
else
    echo "Error: File $i/network/admin/listener.ora does not exist." >> /tmp/discover.log
fi
done