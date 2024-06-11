#!/bin/bash
#set -e

if [ $# -lq 1]; then 
    echo $0' [cm/cmm/db]'
    echo 'Bye!'
fi

test_mode=$1
if [ $test_mode == "cm" ]; then
    test_mode_name="CIPHER MACHINE";
elif [ $test_mode == "db" ]; then
    test_mode_name="DATABASE_CENTER";
elif [ $test_mode == "cmm" ]; then
    test_mode_name="cmm";
else
    echo 'Bye!'
    exit -1
fi

echo 'Welcome to inspection shell for '$test_mode_name'. '
echo 'Current Version: 1.1'


tomorrow="$(date -d "tomorrow" +"%Y-%m-%d")"
step_num=1


### Step 1: Create the Result Dictory
echo -e '\n\033[36mStep '${step_num}': Create the result'"'"'s Dictory...\033[0m'
#home_directory="$(sudo cat /etc/passwd | grep /bin/bash | awk -F':' '$3>999{print $6}')"
home_directory=$HOME
#echo $home_directory

result_directory="${home_directory}/${tomorrow}Result"
echo 'Result directory = '$result_directory

if [ -d $result_directory ]; then
    #read -p 'Result directory exist. Want to rebuilt ? (Y/N): ' my_rebuilt
    #if [ $my_rebuilt == "Y" ] || [ $my_rebuilt == "y" ]; then
        sudo rm -rf $result_directory
    #else
    #    echo 'Bye!'
    #   exit 0
    #fi
fi

mkdir $result_directory
echo -e '\033[32mStep '${step_num}' - finish!\033[0m'



### Step 2: Hardware and System Information
step_num=$[$step_num+1];
echo -e '\n\033[36mStep '${step_num}': Hardware and System Information Collection...\033[0m'
hardware_and_system_directory=${result_directory}"/hardware_and_system"
mkdir $hardware_and_system_directory

hardware_and_system_result=$hardware_and_system_directory"/result.txt"
touch $hardware_and_system_result

## Kernel Version
echo -e '# Linux Kernel Version: '"$(uname -r)" >> $hardware_and_system_result
echo -e 'Get Linux Kernel Version: \033[32mSuccess\033[0m'

## System Version
echo -e '\n# Linux System Version: '"$(lsb_release -d | awk -F'[:\t]' '{print $3}')" >> $hardware_and_system_result
echo -e 'Get Linux System Version: \033[32mSuccess\033[0m'

## USB-Device
echo -e '\n# USB Device: ' >> $hardware_and_system_result
lsusb >> $hardware_and_system_result
echo -e '\n' >> $hardware_and_system_result
        # usb_device_result="$(lsusb)"
        # echo $usb_device_result
        # usb_device_result_array=($usb_device_result)
        # echo 'USB Device Number: ('${#usb_device_result_array[@]}')' >> $hardware_and_system_result
echo -e 'Get USB Device Info: \033[32mSuccess\033[0m'

## General Netcard conf
ifconfig_result_file=$hardware_and_system_directory"/ifconfig.txt"
ifconfig > $ifconfig_result_file

running_netcard="$(cat $ifconfig_result_file | grep "Ethernet" | awk '{print $1}')"
name_ip="$(cat $ifconfig_result_file | grep "inet addr" | awk '{print $2}' | awk -F: '{print $2}' | head -n 1)"
running_netcard_array=($running_netcard)
echo -ne "\n# Running Netcard Number: (${#running_netcard_array[@]}) " >> $hardware_and_system_result

## General Netcard info
ethtool_file_directory=$hardware_and_system_directory"/general_network_ports"
mkdir $ethtool_file_directory
for var in ${running_netcard_array[@]}
do
    echo -n $var' ' >> $hardware_and_system_result
    ethtool_file=$ethtool_file_directory"/"$var".txt"
    sudo ethtool $var > $ethtool_file
    echo -e "\n" >> $ethtool_file
    sudo ethtool -i $var >> $ethtool_file
done
echo -ne "\n" >> $hardware_and_system_result 
echo -e 'Get Running Netcard Info and Firmware Version: \033[32mSuccess\033[0m'

## Memory Series
echo -ne "\n# Memory Series: " >> $hardware_and_system_result 
memory_result_file=$hardware_and_system_directory"/lshw_memory.txt"
        # TODO: HOW TO RUN 'lshw' ONLY ONCE? 
sudo lshw -C memory > $memory_result_file
memory_serial="$(cat $memory_result_file | grep "serial:" | grep -v "NO DIMM" | awk '{gsub(/^\s+|\s+$/, "");print}' | awk '{print $2}')" 
memory_serial_array=($memory_serial)
for var in ${memory_serial_array[@]}
do
    echo -n $var' ' >> $hardware_and_system_result 
done
echo -ne "\n" >> $hardware_and_system_result 
echo -e 'Get Memory Info: \033[32mSuccess\033[0m'

## Disk Series
echo -ne "\n# Disk Series: " >> $hardware_and_system_result 
disk_result_file=$hardware_and_system_directory"/lshw_disk.txt"
        # TODO: HOW TO RUN 'lshw' ONLY ONCE? 
sudo lshw -C disk > $disk_result_file
disk_serial="$(cat $disk_result_file | grep "serial:" | grep -v "NO DIMM" | awk '{gsub(/^\s+|\s+$/, "");print}' | awk '{print $2}')" 
disk_serial_array=($disk_serial)
for var in ${disk_serial_array[@]}
do
    echo -n $var' ' >> $hardware_and_system_result 
done
echo -ne "\n" >> $hardware_and_system_result 
echo -e 'Get Disk Info: \033[32mSuccess\033[0m'

## Disk Usage
echo -ne "\n# Disk Usage: " >> $hardware_and_system_result 
disk_free_file=$hardware_and_system_directory"/disk_free.txt"
df -h > $disk_free_file
disk_local_address="$(cat $disk_result_file | grep "logical name" | awk '{gsub(/^\s+|\s+$/, "");print}' | awk '{print $3}')"
disk_local_address_array=($disk_local_address)
for var in ${disk_local_address[@]}
do
    echo -n $var' ' >> $hardware_and_system_result
    echo -ne "$(cat $disk_free_file | grep $var | awk '{print $5}')" >> $hardware_and_system_result 
    echo -ne ' ' >> $hardware_and_system_result
done
echo -ne "\n" >> $hardware_and_system_result
echo -e 'Get Disk Usage: \033[32mSuccess\033[0m'
        #TODO: IF MORE sds (LIKE sda AND sdb)?

## CPU ID
echo -ne '\n# CPU ID' >> $hardware_and_system_result
echo "$(sudo dmidecode -t 4 | grep ID)" >> $hardware_and_system_result
echo -e 'Get CPU ID: \033[32mSuccess\033[0m'

## CPU Info
echo -ne '\n# CPU Info' >> $hardware_and_system_result
cpu_info_file=$hardware_and_system_directory"/cpu_info.txt"
lscpu >> $cpu_info_file
echo -e 'Get CPU Info: \033[32mSuccess\033[0m'

## GPU Info (only cm/cmm)
if [ $test_mode == "cm" ] || [ $test_mode == "cmm" ]; then 
    gpu_info_file=$hardware_and_system_directory"/nvidia_info.txt"
    nvidia-smi > $gpu_info_file
    if [ $? -eq 0 ]; then
        echo -e 'Get GPU Info: \033[32mSuccess\033[0m'
    else
        echo -e 'Get GPU Info: \033[31mFailed\033[0m'
    fi
fi


mkdir $hardware_and_system_directory/syslog
cp -r /var/log $hardware_and_system_directory/syslog

## HighSpeed Port Info (only cm)
if [ $test_mode == "cm" ]; then 
    optical_fiber_ports_number="$(lspci | grep -i Eth | grep -E '10-G|10G|40-G|40G' | awk '{print $1}')"
    optical_fiber_ports_number_array=($optical_fiber_ports_number)
    if [ ${#optical_fiber_ports_number_array[@]} -ne 0 ]; then
        echo -e 'Get HighSpeed Port Number: \033[32mSuccess\033[0m'
    else
        echo -e 'Get HighSpeed Port Number: \033[31mNo 10G/40G Port\033[0m'
    fi
    optical_fiber_directory=$hardware_and_system_directory"/high_speed_network_ports"
    mkdir $optical_fiber_directory
    for var in ${optical_fiber_ports_number_array[@]}
    do
        optical_fiber_file_name=$optical_fiber_directory"/"$var".txt"
        lspci -s $var -vv > $optical_fiber_file_name
        echo -e 'Get HighSpeed Port '$var' Status: \033[32mSuccess\033[0m'
    done

    # Get DPDK Directory
    dpdk_directory="$(cat /root/start_server.sh | grep "dpdk-" | grep -v "#" | awk '{print $NF}')"
    echo "Dpdk Directory: "$dpdk_directory
    echo "\n# Dpdk Dicectory: "$dpdk_directory >> $hardware_and_system_result

    # Get DPDK Result
    dpdk_result_file=$hardware_and_system_directory"/dpdk_status.txt"
    $dpdk_directory/usertools/dpdk-devbind.py --status > $dpdk_result_file
    if [ $? -eq 0 ]; then
        echo -e 'Get DPDK Status: \033[32mSuccess\033[0m'
    else
        echo -e 'Get DPDK Status: \033[31Failed\033[0m'
    fi
            #   TODO: CHECK IF HIGHSPEED PORTS ARE IN DPDK @liwenyuan

    memory_free_file=$hardware_and_system_directory"/memory_free.txt"
    free -h > $memory_free_file
    echo -e 'Get Memory Usage: \033[32mSuccess\033[0m'
fi

echo -e '\033[32mStep '${step_num}' - finish!\033[0m'

### Step 3: Process & Server Information
step_num=$[$step_num+1];
echo -e '\n\033[36mStep '${step_num}': Process and Server Information Collection...\033[0m'
process_directory=${result_directory}"/process"
mkdir $process_directory

process_result=$process_directory"/result.txt"
touch $process_result

## All Service
all_service_file=$process_directory"/all_service_state.txt"
service --status-all > $all_service_file
echo -e 'Get All Services Status: \033[32mSuccess\033[0m'

## All Process Status
process_state_file=$process_directory"/all_process_state.txt"
ps -ef > $process_state_file
echo -e 'Get All Processes'"'"' Status: \033[32mSuccess\033[0m'

## CM 8 Servers' Status (only cm/cmm)
if [ $test_mode == "cm" ] || [ $test_mode == "cmm" ]; then 
    server_process_state_file=$process_directory"/server_process_state.txt"
    echo -e "$(ps -eo pid,ppid,lstart,etime,cmd | grep "/root/server_")" > $server_process_state_file
    echo -e 'Get servers'"'"' Processes Status: \033[32mSuccess\033[0m'
    server_process_ids="$(cat $server_process_state_file | awk '$2 != 1 && $2 <= 100000 {print $1}')"
    process_id_array+=($server_process_ids)
fi


## CM VEC's Status (only cm/cmm)
if [ $test_mode == "cm" ] || [ $test_mode == "cmm" ]; then 
    vec_process_state_file=$process_directory"/vec_process_state.txt"
    echo -e "$(ps -eo pid,ppid,lstart,etime,cmd | grep "VECProject")" > $vec_process_state_file
    echo -e 'Get VEC'"'"'s Processes Status: \033[32mSuccess\033[0m'
    vec_process_ids="$(cat $vec_process_state_file | awk '$2 != 1 && $2 <= 100000 {print $1}')"
    vec_process_id_array=($vec_process_ids)
    process_id_array+=($vec_process_ids)
fi

## SNMP'S Status (only cm)
if [ $test_mode == "cm" ]; then 
    snmp_process_state_file=$process_directory"/snmp_process_state.txt"
    echo -e "$(ps -eo pid,ppid,lstart,etime,cmd | grep "/root/hsm_snmp_trap")" > $snmp_process_state_file
    echo -e 'Get SNMP'"'"'s Processes Status: \033[32mSuccess\033[0m'
    snmp_process_ids="$(cat $snmp_process_state_file | awk '$2 != 1 && $2 <= 100000 {print $1}')"
    snmp_process_id_array=($vec_process_ids)
    process_id_array+=($snmp_process_ids)
fi

## KEEPALIVED's Status (only db)
if [ $test_mode == "db" ]; then 
    keepalived_server_state_file=$process_directory"/keepalived_server_state.txt"
    service mysql status > $keepalived_server_state_file
    echo -e 'Get MySQL Server Status: \033[32mSuccess\033[0m'
fi

## MYSQL's Status (only db)
if [ $test_mode == "db" ]; then 
    mysql_server_state_file=$process_directory"/mysql_server_state.txt"
    service mysql status > $mysql_server_state_file
    echo -e 'Get MySQL Server Status: \033[32mSuccess\033[0m'
fi

## for every PID
echo ${process_id_array[@]}
echo 'Process ID Count: '${#process_id_array[@]}
for var in ${process_id_array[@]}
do
    if [ -d /proc/$var ]; then
        process_file=$process_directory"/"$var".txt"
        sudo ls -l /proc/$var | grep exe > $process_file
        process_start_path="$(cat $process_file | awk '{print $NF}')"
        echo -en '\n' >> $process_file

        sudo stat $process_start_path >> $process_file
        echo -e 'Get '$var"'"'s Location and Status: \033[32mSuccess\033[0m'
    else
        echo -e 'Get '$var"'"'s Location and Status: \033[34mNo such PID\033[0m'
    fi
done

#ntp_addr="time1.aliyun.com"
#echo "$ ntpdate '${ntp_addr}' >> result.txt" >> $process_result
#ntpdate $ntp_addr >> $process_result
#if [ $? -eq 0 ]; then
#    echo -e 'Get NTPDATE: \033[32mSuccess\033[0m'
#else
#    echo -e 'Get NTPDATE: \033[31mFailed\033[0m'
#fi
#echo -en '\n' >> $process_result


echo -e '\033[32mStep '${step_num}' - finish!\033[0m'

### Step 4: Network Ports and Sockets Collection
step_num=$[$step_num+1];
echo -e '\n\033[36mStep '${step_num}':  Network Ports and Sockets Collection...\033[0m'
port_and_socket_directory=${result_directory}"/port_and_socket"
mkdir $port_and_socket_directory

process_result=$port_and_socket_directory"/result.txt"
touch $process_result

## NetStat
netstat_result_file=$port_and_socket_directory"/netstat.txt"
sudo netstat -tlunp > $netstat_result_file
if [ $? -eq 0 ]; then
    echo -e 'Get NetStat Info: \033[32mSuccess\033[0m'
else
    echo -e 'Get NetStat Info: \033[31mFailed\033[0m'
fi

## Sockets
cat /proc/net/tcp > $port_and_socket_directory"/tcp.txt"
cat /proc/net/udp > $port_and_socket_directory"/udp.txt"
cat /proc/net/icmp > $port_and_socket_directory"/icmp.txt"
echo -e 'Get TCP/UDP/ICMP Info: \033[32mSuccess\033[0m'

echo ${process_id_array[@]}

## Every PID's Sockets
for var in ${process_id_array[@]}
do
    # if not exist, continue
    if [ -d /proc/$var ]; then
        process_file=$process_directory"/"$var".txt"
        echo -en "\nHandle Number: " >> $process_file
        sudo ls -l /proc/$var/fd | wc -l >> $process_file

        echo -e "\nHandle: " >> $process_file
        sudo ls -l /proc/$var/fd >> $process_file
        echo -e 'Get '$var"'"'s Handles Satus: \033[32mSuccess\033[0m'
    else
        echo -e 'Get '$var"'"'s Handles Satus: \033[34mNo such PID\033[0m'
        continue
    fi
done
echo -e '\033[32mStep '${step_num}' - finish!\033[0m'

### Step 5: User and Password Collection
step_num=$[$step_num+1];
echo -e '\n\033[36mStep '${step_num}':  User and Password Collection...\033[0m'
user_and_password_directory=${result_directory}"/user_and_password"
mkdir $user_and_password_directory

process_result=$user_and_password_directory"/result.txt"
touch $process_result

## All Users
user_all_file=$user_and_password_directory"/user_all.txt"
cat /etc/passwd > $user_all_file
echo -e 'Get User Info: \033[32mSuccess\033[0m'

## Bash Users
users="$(cat $user_all_file | grep "/bin/bash" | awk -F':' '$3>999{print $0}'| awk -F'[:\t]' '{print $1}')"
users_array=($users)

user_bash_file=$user_and_password_directory"/user_bash.txt"
cat /etc/passwd | grep /bin/bash > $user_bash_file
echo -e 'Get User Bash Info: \033[32mSuccess\033[0m'

echo -e 'Get Password Period Info: Temporarily Unsupported... Please wait'

echo -e '\033[32mStep '${step_num}' - finish!\033[0m'


### Step 6: Logins and Commands Collection
step_num=$[$step_num+1];
echo -e '\n\033[36mStep '${step_num}': Login and Command Information test...\033[0m'
login_and_command_directory=${result_directory}"/login_and_command"
mkdir $login_and_command_directory
process_result=$login_and_command_directory"/result.txt"
touch $process_result

## last
login_file=$login_and_command_directory"/last.txt"
sudo last > $login_file
if [ $? -eq 0 ]; then
    echo -e 'Get Last Login Info: \033[32mSuccess\033[0m'
else
   echo -e 'Get Last Login Info: \033[31mFailed\033[0m'
fi

## bash_history
# root bash_history
sudo cp /root/.bash_history $login_and_command_directory/.
mv $login_and_command_directory/.bash_history $login_and_command_directory/root_bash_history

# other user's bash_history
for var in ${users_array[@]}
do
    sudo cp /home/$var/.bash_history $login_and_command_directory/.
    if [ $? -eq 0 ]; then
        echo -e 'Get '$var' bash_history: \033[32mSuccess\033[0m'
    else
        echo -e 'Get '$var' bash_history: \033[31mFailed\033[0m'
    fi
    mv $login_and_command_directory/.bash_history $login_and_command_directory/$var'_bash_history'
done

last_login_statistics=$(last | grep $LOGNAME |awk '{print $1}'|wc -l)
echo $last_login_statistics >> $process_result
echo -e 'Get last_login_statistics: \033[32mSuccess\033[0m'

### Step 7: Configure Collection
step_num=$[$step_num+1];
echo -e '\n\033[36mStep '${step_num}':  Configure Collection...\033[0m'
config_directory=${result_directory}"/config"
mkdir $config_directory
process_result=$config_directory"/result.txt"
touch $process_result

#sudo find /root -type f -exec file {} \; | grep '.\.config\>' | awk -F ':' '{print $1}'

if [ $test_mode == "cm" ] || [ $test_mode == "cmm" ]; then 
    # VEC config
    echo -n 'Path 1: /root -> find "config_*": '
    sudo find /root -maxdepth 1 -type f -exec file {} \; | grep 'config_' | awk -F ':' '{print $1}' >> $process_result
    echo $?

    echo -n 'Path 2: /root -> find "*.conf": '
    sudo find /root -maxdepth 1 -type f -exec file {} \; | grep '\.conf' | awk -F ':' '{print $1}' >> $process_result
    echo $?

    echo -n 'Path 3: /root/Code/* -> find "*.config": '
    sudo find /root/Code -type f -exec file {} \; | grep '\.config' | awk -F ':' '{print $1}' >> $process_result
    echo $?
    echo -n 'Path 4: /root/VECProject/* -> find ".config": '
    sudo find /root/VECProject -type f -exec file {} \; | grep '\.config' | awk -F ':' '{print $1}' >> $process_result
    echo $?
    echo -n 'Path 5: /root/VEC/* -> find ".config": '
    sudo find /root/VEC -type f -exec file {} \; | grep '\.config' | awk -F ':' '{print $1}' >> $process_result
    echo $?
elif [ $test_mode == "db" ]; then
    echo -n 'Path 1: KeepAlived Configure: '
    sudo find /etc/keepalived -maxdepth 1 -type f -exec file {} \; | grep '.conf' | awk -F ':' '{print $1}' >> $process_result
    echo $?

    echo -n 'Path 2: MySQLd Configure: '
    sudo find /etc/mysql/mysql.conf.d -maxdepth 1 -type f -exec file {} \; | grep '.cnf' | awk -F ':' '{print $1}' >> $process_result
    echo $?
fi

cat $process_result | while read line
do
    #echo $line
    cat $line > $config_directory"/$(echo $line | sed 's#/#_#g')"
done

echo -e '\033[32mStep '${step_num}' - finish!\033[0m'

### Step 8: MySQL 
if [ $test_mode == "db" ]; then 
    step_num=$[$step_num+1];
    echo -e '\n\033[36mStep '${step_num}':  MySQL Data...\033[0m'
    mysql_directory=${result_directory}"/mysql"
    mkdir $mysql_directory
    process_result=$mysql_directory"/result.txt"
    touch $process_result

# try password
    read -p 'Input MySQL ROOT password: ' -s root_passwd
    mysql -u root -p$root_passwd -e "exit"
    while [ $? -eq 1 ]
    do
        read -p 'Wrong! Input MySQL ROOT password: ' -s root_passwd
        mysql -u root -p$root_passwd -e "exit"
    done

## slave status
    mysql -u root -p$root_passwd -e "show slave status\G;" > $mysql_directory"/slave.txt"
    if [ $? -eq 0 ]; then
        echo -e 'Get MySQL Slave Status: \033[32mSuccess\033[0m'
    else
        echo -e 'Get MySQL Slave Status: \033[31mFailed\033[0m'
    fi

# user table
    mysql_user_file=$mysql_directory"/user.txt"
    mysql -u root -p$root_passwd -e "use mysql; select user, host from user;" > $mysql_user_file
    if [ $? -eq 0 ]; then
        echo -e 'Get MySQL Users Status: \033[32mSuccess\033[0m'
    else
        echo -e 'Get MySQL Users Status: \033[31mFailed\033[0m'
    fi

# for all users
    user_count="$(cat $mysql_user_file | wc -l)"
    for i in `seq 2 $user_count`
    do
        user_name="$(head -$i $mysql_user_file | tail -1 | awk '{print $1}')"
        user_host="$(head -$i $mysql_user_file | tail -1 | awk '{print $2}')"

        user_grant_file=$mysql_directory"/"$user_name"_"$user_host".txt"

        mysql -u root -p$root_passwd -e "show grants for $user_name@'$user_host'\G;" > $user_grant_file
        if [ $? -eq 0 ]; then
            echo -e 'Get MySQL '$user_name'@'$user_host' Status: \033[32mSuccess\033[0m'
        else
            echo -e 'Get MySQL '$user_name'@'$user_host' Status: \033[31mFailed\033[0m'
        fi
    done
    echo -e '\033[32mStep '${step_num}' - finish!\033[0m'
fi

echo -e "The script runs successfully! Results are in "$result_directory

### Step 8: Packaging
step_num=$[$step_num+1];
today_date=$(date +%Y%m%d)
echo -e '\n\033[36mStep '${step_num}':  Packaging...\033[0m'
if [ $test_mode == "cm" ] || [ $test_mode == "cmm" ]; then 
    sudo tar -cvf /home/cm/data_ext_result_$today_date_$name_ip".tar" $result_directory
    sudo chmod 666 /home/cm/data_ext_result_$today_date_$name_ip".tar"
    echo -e '\n\033[36mSuccess! Package Directory: /home/cm/data_ext_result_'$name_ip'".tar"\033[0m'
elif [ $test_mode == "db" ]; then 
    sudo tar -cvf /home/chinamobile/data_ext_result_$today_date_$name_ip".tar" $result_directory
    sudo chmod 666 /home/chinamobile/data_ext_result_$today_date_$name_ip".tar"
    echo -e '\n\033[36mSuccess! Package Directory: /home/chinamobile/data_ext_result_'$name_ip'".tar"\033[0m'
fi

sudo rm -rf $result_directory

echo -e "\nPlease export this file.\n\nBye!"
