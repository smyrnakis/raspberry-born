#!/bin/bash

# Based on the script https://github.com/gagle/raspberrypi-motd/blob/master/motd.sh

clear

function color (){
  echo "\e[$1m$2\e[0m"
}

function extend (){
  local str="$1"
  let spaces=60-${#1}
  while [ $spaces -gt 0 ]; do
    str="$str "
    let spaces=spaces-1
  done
  echo "$str"
}

function center (){
  local str="$1"
  let spacesLeft=(78-${#1})/2
  let spacesRight=78-spacesLeft-${#1}
  while [ $spacesLeft -gt 0 ]; do
    str=" $str"
    let spacesLeft=spacesLeft-1
  done

  while [ $spacesRight -gt 0 ]; do
    str="$str "
    let spacesRight=spacesRight-1
  done

  echo "$str"
}

function sec2time (){
  local input=$1

  if [ $input -lt 60 ]; then
    echo "$input seconds"
  else
    ((days=input/86400))
    ((input=input%86400))
    ((hours=input/3600))
    ((input=input%3600))
    ((mins=input/60))

    local daysPlural="s"
    local hoursPlural="s"
    local minsPlural="s"

    if [ $days -eq 1 ]; then
      daysPlural=""
    fi

    if [ $hours -eq 1 ]; then
      hoursPlural=""
    fi

    if [ $mins -eq 1 ]; then
      minsPlural=""
    fi

    echo "$days day$daysPlural, $hours hour$hoursPlural, $mins minute$minsPlural"
  fi
}

borderColor=35
headerLeafColor=32
headerRaspberryColor=31
greetingsColor=36
statsLabelColor=33

borderLine="━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
borderTopLine=$(color $borderColor "┏$borderLine┓")
borderBottomLine=$(color $borderColor "┗$borderLine┛")
borderBar=$(color $borderColor "┃")
borderEmptyLine="$borderBar                                                                              $borderBar"

# Header
header="$borderTopLine\n$borderEmptyLine\n"
header="$header$borderBar$(color $headerLeafColor "          .~~.   .~~.                                                         ")$borderBar\n"
header="$header$borderBar$(color $headerLeafColor "         '. \ ' ' / .'                                                        ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "          .~ .~~~..~.                      _                          _       ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "         : .~.'~'.~. :     ___ ___ ___ ___| |_ ___ ___ ___ _ _    ___|_|      ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "        ~ (   ) (   ) ~   |  _| .'|_ -| . | . | -_|  _|  _| | |  | . | |      ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "       ( : '~'.~.'~' : )  |_| |__,|___|  _|___|___|_| |_| |_  |  |  _|_|      ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "        ~ .~ (   ) ~. ~               |_|                 |___|  |_|          ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "         (  : '~' :  )                                                        ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "          '~ .~~~. ~'                                                         ")$borderBar\n"
header="$header$borderBar$(color $headerRaspberryColor "              '~'                                                             ")$borderBar"

me=$(whoami)
hostname=$(hostname)

# Greetings
greetings="$borderBar$(color $greetingsColor "$(center "Welcome on $hostname, $me!")")$borderBar\n"
greetings="$greetings$borderBar$(color $greetingsColor "$(center "$(date +"%A, %d %B %Y, %T")")")$borderBar"

# System information
read loginFrom loginIP loginDate <<< $(last $me --time-format iso -2 | awk 'NR==2 { print $2,$3,$4 }')

# TTY login
if [[ $loginDate == - ]]; then
  loginDate=$loginIP
  loginIP=$loginFrom
fi

if [[ $loginDate == *T* ]]; then
  login="$(date -d $loginDate +"%A, %d %B %Y, %T") ($loginIP)"
else
  # Not enough logins
  login="None"
fi

labelLogin="$(extend "$login")"
labelLogin="$borderBar  $(color $statsLabelColor "Last Login....:") $labelLogin$borderBar"

uptime="$(sec2time $(cut -d "." -f 1 /proc/uptime))"
uptime="$uptime ($(date -d "@"$(grep btime /proc/stat | cut -d " " -f 2) +"%d-%m-%Y %H:%M:%S"))"

labelUptime="$(extend "$uptime")"
labelUptime="$borderBar  $(color $statsLabelColor "Uptime........:") $labelUptime$borderBar"

if [ -f /run/systemd/shutdown/scheduled ]; then
  shutdownTime=$(date '+%F %H:%M' -d "@$( awk -F '=' '/USEC/{ $2=substr($2,1,10); print $2 }' /run/systemd/shutdown/scheduled )")
  shutdownMode="$( awk -F '=' '/MODE/{ print $2 }' /run/systemd/shutdown/scheduled )"
  shutdownFull="scheduled ${shutdownMode} for ${shutdownTime}"
  labelShutdown="$(extend "$shutdownFull")"
  labelShutdown="$borderBar  $(color $statsLabelColor "Shutdown......:") $labelShutdown$borderBar"
fi

labelMemory="$(extend "$(free -m | awk 'NR==2 { printf "Total: %sMB, Used: %sMB, Free: %sMB",$2,$3,$4; }')")"
labelMemory="$borderBar  $(color $statsLabelColor "Memory........:") $labelMemory$borderBar"

labelSD="$(extend "$(df -h ~ | awk 'NR==2 { printf "Total: %sB, Used: %sB, Free: %sB",$2,$3,$4; }')")"
labelSD="$borderBar  $(color $statsLabelColor "Home space....:") $labelSD$borderBar"

# https://stackoverflow.com/questions/8334266/how-to-make-special-characters-in-a-bash-script-for-conky?noredirect=1&lq=1
CEL=$'\xc2\xb0'C
labelTemp="$(extend "$(/usr/bin/vcgencmd measure_temp | cut -c "6-9")${CEL}")"
#labelTemp="$(extend "$(/opt/vc/bin/vcgencmd measure_temp | cut -c "6-9")${CEL}")"
#labelTemp="$(extend "$(/opt/vc/bin/vcgencmd measure_temp | cut -c "6-9")ºC")"
labelTemp="$borderBar  $(color $statsLabelColor "CPU temp......:") $labelTemp$borderBar"

# THIS PART SHOULD BE USED ONLY IF DHT11 SENSOR IS AVAILABLE AS DESCRIBED HERE:
# https://github.com/smyrnakis/raspberry-born/blob/main/chapters/thingSpeak.md
ambientTemp="$(cat /home/$me/Software/thingspeak/temperature)"
ambientHum="$(cat /home/$me/Software/thingspeak/humidity)"
environment="Temperature: ${ambientTemp}${CEL} Humidity: ${ambientHum}%"
labelEnvironment="$(extend "$environment")"
labelEnvironment="$borderBar  $(color $statsLabelColor "Environemnt...:") $labelEnvironment$borderBar"
# ############################################################################

if [ -f /run/systemd/shutdown/scheduled ]; then
  stats="$labelLogin\n$labelUptime\n$labelShutdown\n$labelMemory\n$labelSD\n$labelEnvironment\n$labelTemp"
else
  stats="$labelLogin\n$labelUptime\n$labelMemory\n$labelSD\n$labelEnvironment\n$labelTemp"
fi

# Print motd
echo -e "$header\n$borderEmptyLine\n$greetings\n$borderEmptyLine\n$stats\n$borderEmptyLine\n$borderBottomLine"