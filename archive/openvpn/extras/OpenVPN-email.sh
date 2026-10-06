#!/bin/bash

# This script is monitoring OpenVPN log ( /var/log/openvpn-status.log )
# and notify via email on client's connection / disconnection.
# Replace {YOUR-EMAIL} on 'recipient' variable (line 14).
#
# 2021/02/01 - Apostolos Smyrnakis
# Updated 2024/10/11
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
    if [[ "$recipient" == "{YOUR-EMAIL}" ]]; then
        echo "Error: Please replace '{YOUR-EMAIL}' with the recipient's email address."
        exit 1
    fi

    # extract 'client name' , 'source IP' , 'connected since'
    logExtract=$( tail -n +4 /var/log/openvpn-status.log | grep 'CLIENT_LIST' | awk -F ',' '{print $2,$3,$8}' )

    if [[ ! -z "$logExtract" ]]; then
        if [[ "$oldConnected" != "$logExtract" ]]; then
            numOfConnected=$(echo "$logExtract" | grep -c '^')

            oldConnected="$logExtract"
            flagDisconnected=0

            emailMessage="\r\n"
            echo "$logExtract" | ( while read LINE; do
                connectedDetails=($LINE)
                emailMessage+="\t-->  '${connectedDetails[0]}'   from   ${connectedDetails[1]}   since   ${connectedDetails[3]}, ${connectedDetails[2]}\r\n "
            done

            if ! echo -e "Subject: OpenVPN on ${hostn}\r\n\r\nCurrently connected client(s):\r\n\r\n${emailMessage}\r\n" | /usr/bin/msmtp --from=default --syslog=on -t ${recipient}; then
                echo "Error: Failed to send email notification for connected clients."
            fi
            )
        fi
    else
        if [[ "$flagDisconnected" -ne 1 ]]; then
            flagDisconnected=1

            if ! echo -e "Subject: OpenVPN on ${hostn}\r\n\r\nAll clients DISCONNECTED\r\n\r\n" | /usr/bin/msmtp --from=default --syslog=on -t ${recipient}; then
                echo "Error: Failed to send email notification for disconnected clients."
            fi
        fi
    fi
}


while true; do
    operation
    sleep 10
done
