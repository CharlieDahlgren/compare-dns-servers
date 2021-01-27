#!/bin/bash
rtt_arr1=()
rtt_arr2=()
srv_arr1=()
srv_arr2=()
clear="\r\033[K"
loop_var=""
red="\033[31m"
green="\033[32m"
bold="\033[1m"
reset="\033[0;39m"
while true
do
  while true
  do
    read -r -p "Please enter the first IP address (default Google - 8.8.8.8): " dns1
      if [[ $dns1 =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$ ]]
      then
        printf "${clear}OK! First DNS i set to $dns1.\n"
        break
      elif [ -z $dns1 ]
      then
        printf "${clear}OK! First DNS is set to 8.8.8.8 (default).\n"
        dns1="8.8.8.8"
        break
      elif [[ $dns1 =~ ^255 ]]
      then
        printf "${clear}Funny guy!\n"
      else
        printf "${clear}Please enter a valid IP-adress.\n"
      fi
    done

  while true
  do
    read -r -p "Please enter the second IP address (default Cloudflare - 1.1.1.1): " dns2
      if [[ $dns2 =~ ^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$ ]]
      then
        printf "${clear}OK! First DNS is set to $dns2\n"
        break
      elif [ -z $dns2 ]
      then
        printf "${clear}OK! Second DNS is set to 1.1.1.1 (default).\n"
        dns2="1.1.1.1"
        break
      elif [[ $dns2 =~ ^255 ]]
      then
        printf "${clear}Funny guy!\n"
      else
        printf "${clear}Please enter a valid IP-adress.\n"
      fi
    done

read -r -p "How many tests do you want to run? (0-99, default is 10): " tests
  case $tests in
    [0-9]|[0-9][0-9])
      printf "OK! $tests tests will run per server.\n"
      break ;;
    0)
      printf "OK!"
      exit 69 ;;
    "")
      tests=10
      printf "OK! $tests tests will run per server (default).\n"
      break ;;
    *) printf "Nope, try again\n" ;;
  esac
done

printf "Comparing $dns1 and $dns2\nPlease wait"
for i in {1..3}
do
  printf "."
  sleep 0.5
done

printf "\r\033[K"

loop_n=-0
loop_n2=0
loop_n3=-1
loop_exc="${green}${bold}"

printf "Progress: \n"

for (( i=0; i< $tests; ++i));
  do
  dns1_out=$(dig iana.org +noall +multiline +trace @$dns1)
  dns1_sub=$(printf "$dns1_out" | awk 'gsub(/;; Received [0-9]{0,4} bytes from /, "Server: ")')
  rtt_arr1+=($(printf "$dns1_sub" | awk '{print $4}'))
  loop_exc+="!"
  loop_n=`expr $loop_n + 1`
  loop_n3=`expr $loop_n3 + 1`
  srv_arr1+=($(printf "$dns1_sub" | awk 'gsub(/Server: |#[0-9]{0,4}| in [0-9]{0,4} ms|\(.*\)/, ""){print $1}'))
  printf "$clear$loop_exc"
  sleep 0.3

  dns2_out=$(dig iana.org +noall +multiline +trace @$dns2)
  dns2_sub=$(printf "$dns2_out" | awk 'gsub(/;; Received [0-9]{0,4} bytes from /, "Server: ")')
  rtt_arr2+=($(printf "$dns2_sub" | awk '{print $4}'))
  loop_exc+="!"
  loop_n3=`expr $loop_n3 + 1`
  srv_arr2+=($(printf "$dns2_sub" | awk 'gsub(/Server: |#[0-9]{0,4}| in [0-9]{0,4} ms|\(.*\)/, ""){print $1}'))
  sleep 0.3

done

printf "$clear[DONE]\n${reset}"

x=0
for n in "${srv_arr1[@]}"
do
    if [ $n = $dns1 ]
    then
      x=$((x+1))
      printf "\nTrace ${x}: $n"
    else
      printf " --> $n"
    fi
done

printf "\n"

x=0

for n in "${srv_arr2[@]}"
  do
   if [ $n = $dns2 ]
   then
     x=$((x+1))
       printf "\nTrace ${x}: $n"
     else
      printf " --> $n"
     fi
 done

rtt1=0
rtt2=0
n1=0
n2=0

for value in "${rtt_arr1[@]}";
  do
    rtt1=`expr $rtt1 + $value`
    #printf "$value"
    n1=`expr $n1 + 1`
    #printf "$rtt1 added to variable and n1=$n1 \n"
  done

for value in "${rtt_arr2[@]}";
  do
    rtt2=`expr $rtt2 + $value`
    #printf "$value"
    n2=`expr $n2 + 1`
    #printf "$rtt1 added to variable and n1=$n1 \n"
  done

rtt1_avg=`expr $rtt1 / $n1`
rtt2_avg=`expr $rtt2 / $n2`
dash="------------------------------------------------------------------------"

printf "\n\n$dash\nTotal RTT for $dns1 is $rtt1 ms on $tests traces. Average total RTT is $rtt1_avg ms.\n$dash\n\n$dash\nTotal RTT for $dns2 is $rtt2 ms on $tests traces. Average total RTT is $rtt2_avg ms.\n$dash\n\n"

if [ $rtt1_avg -lt $rtt2_avg ];
  then
  printf "${red}${bold}Use $dns1\n"
elif [ $rtt1_avg = $rtt2_avg ];
  then
  printf "${red}${bold}Both are identical, choose whatever.\n"
else
  printf "${red}${bold}Use $dns2\n"
fi
printf "${reset}\n"
while true
do
  read -r -p "Do you want to see the last output?(Y/N):" output
    case $output in
      [yY]|yes|Yes)
        printf "\n${dns1_out}\n\n${dns1_out}"
        exit ;;
      [nN]|no|No)
        printf "OK!"
        exit ;;
      *)
        printf "Please answer yes or no.\n"
    esac
done
