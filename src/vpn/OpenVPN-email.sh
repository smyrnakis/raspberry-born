#!/bin/bash

# This script is monitoring OpenVPN log ( /var/log/openvpn-status.log )
# and notify via email on client's connection / disconnection.
# Replace {YOUR-EMAIL} on 'recipient' variable (line 13).
#
# 2021/02/01 - Apostolos Smyrnakis
# https://github.com/smyrnakis/raspberry-born/blob/main/src/vpn/OpenVPN-email.sh

echo "Starting script 'OpenVPN-email.sh' to monitor openvpn.log file ..."

hostn=$(/usr/bin/uname -n)
recipient="{YOUR-EMAIL}"

emailMessage="\r\n"
oldConnected=""
flagDisconnected=1

# check openvpn log for connected clients
operation ()
{
    while read j
    do
        #echo "[DEB] file changed"

        # extract 'client name' , 'source IP' , 'connected since'
        # logExtract=$( cat /var/log/openvpn-status.log | tail -n +4 | grep 'CLIENT_LIST' | awk -F ',' '{print $2,$3,$8}' )

        # extract 'client name' , 'source IP'
        logExtract=$( cat /var/log/openvpn-status.log | tail -n +4 | grep 'CLIENT_LIST' | awk -F ',' '{print $2,$3}' )

        if [[ ! -z "$logExtract" ]]; then

            #echo "[DEB] connection(s) detected"

            if [[ "$oldConnected" != "$logExtract" ]]; then

                #echo "[DEB] oldConnected: $oldConnected "
                #echo "[DEB] logExtract: $logExtract "

                # count lines in 'logExtract'
                numOfConnected=$(echo "$logExtract" | grep -c '^')
                #echo "[DEB] numOfConnected: $numOfConnected "

                oldConnected="$logExtract"

                # permit sending 'all disconnected' email only after at least one client was connected
                flagDisconnected=0

                echo "$logExtract" | ( while read LINE; do
                    #echo "[DEB] reading logExtract"

                    connectedDetails=($LINE)
                    emailMessage+="\t-->  '${connectedDetails[0]}'   from   ${connectedDetails[1]} \r\n "

                    #echo "[DEB] currently connected: ${connectedDetails[0]} from ${connectedDetails[1]}"
                done

                echo -e "Subject: OpenVPN on ${hostn}\r\n\r\nCurrently connected client(s):\r\n\r\n${emailMessage}\r\n" | /usr/bin/msmtp --from=default --syslog=on -t ${recipient}
                #echo "[DEB] email sent: $emailMessage "
                )
            fi
        else
            if [[ "$flagDisconnected" -ne 1 ]]; then
                flagDisconnected=1

                echo -e "Subject: OpenVPN on ${hostn}\r\n\r\nAll clients DISCONNECTED\r\n\r\n" | /usr/bin/msmtp --from=default --syslog=on -t ${recipient}
                #echo "[DEB] all clients disconnected"
            fi
        fi
        break
    done <  <(/usr/bin/inotifywait -q -e modify /var/log/openvpn-status.log)
}


while true; do
    operation
done