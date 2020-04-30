#!/bin/bash

###--===============================================
# https://github.com/XX-net/XX-Net/issues/8425
# macOS 10.13.1按照教程操作一遍可正常使用，用的时间不长，稳定性未测试

# 可以用Automator做个AppleScript的程序，把每次重启或切换网络要运行的命令放一起：

# on run {input, parameters}

#	do shell script "sudo kextload /Applications/Tunnelblick.app/Contents/Resources/tun-signed.kext;sudo pkill -9 miredo;sudo /opt/local/sbin/miredo;/存放xx路径/start" password "系统密码" with administrator privileges
	
#	return input
#end run

###--===============================================以上部分是网上拷贝，没有研究过，暂不用看。
# 注：” 不是 "!!!
function tuntaposx_status() {
    kextstat | grep net.sf.tuntaposx.tun > /dev/null 2>&1 ;
    tuntaposx_tun=$((1-$?))
    kextstat | grep net.sf.tuntaposx.tap > /dev/null 2>&1 ;
    tuntaposx_tap=$((1-$?))
}

# 传入参数形式：kext_status net.sf.tuntaposx.tun
function kext_status() {
    kextstat | grep "$1" > /dev/null 2>&1 ;
    v_kext_status=$((1-$?))

    kext_status_kextname=$1

    if [ $v_kext_status == 1 ] ; then
        echo "$kext_status_kextname is loaded"
        echo "显示 $kext_status_kextname 加载信息"
        kextstat | grep $kext_status_kextname | awk '{print $1"_"$6}'
    else
        echo "$kext_status_kextname is not loaded"
    fi

    RETURN_VALUE=$?
    echo "The exit code of [kext_status:$1] function is $RETURN_VALUE."
}

# 本函数实时获取通用进程当前是否运行, =1为运行状态，=0为非运行状态
# 用参数传递进程名，就不用每个进程都写一个函数了！
function process_status() {
    # 注意：PIDS这个变量已在全局用，而函数中也是会影响到全局变量的值，故这里就要另起变量名。
    PIDS_process_status=`pgrep -l $1 | awk '{print $1}'`
    ## 增加一个状态判断
    ## 为何这里要用两层square bracket，不然会报错（在MiredoErrLoad.log文件）要了解清楚
    ## 两种解决方法：变量加双引号，或者加双方括弧。
    if [ "$PIDS_process_status" == "" ] ; then
    ## if [[ $PIDS_process_status == "" ]] ; then
	echo "$1:PIDS_process_status:为空，说明 $1 未运行！"
    else
        echo "$1:PIDS_process_status:["$PIDS_process_status"]！"
    fi
    # pgrep -l "$1" | awk '{print $1}' > /dev/null 2>&1 ; # -- 不能用这句！
    pgrep -l "$1" > /dev/null 2>&1 ;
    v_process_status=$((1-$?))

    process_status_processname=$1

    RETURN_VALUE=$?
    echo "The exit code of [process_status] function is $RETURN_VALUE."
}

# 本函数实现如果kext正在运行，就卸载掉的功能
function kext_unload() {
    ## 注意：使用通用的带参状态函数，就不必每次需要进程状态，都写一个函数了
    kext_status "$1"
    echo "v_kext_status=$v_kext_status"
    if [ $v_kext_status == 1 ] ; then
        echo "Already $kext_status_kextname"
        echo "准备卸载$1!"
        # sudo pkill -9 "$1"
        sudo kextunload -b $1
        echo “等待1秒，以便{$1}卸载完成。”
        sleep 1  #等待1秒，以便卸载完成。
        echo "$1 has been unloaded"

    else
        echo "$kext_status_kextname not run! not need unload"
    fi

    RETURN_VALUE=$?
    echo "The exit code of [kext_unload:$1] function is $RETURN_VALUE."
}

# 本函数实现如果process正在运行，就卸载掉的功能
function process_unload() {
    ## 注意：使用通用的带参状态函数，就不必每次需要进程状态，都写一个函数了
    process_status "$1"
    echo "v_process_status=$v_process_status"
    if [ $v_process_status == 1 ] ; then
        echo "Already $process_status_processname"
        echo "准备卸载$1!"
        sudo pkill -9 "$1"
        echo “等待1秒，以便{$1}卸载完成。”
        sleep 1  #等待1秒，以便卸载完成。
        echo "$1 has been batch killed"

    else
        echo "$process_status_processname not run! not need unload"
    fi

    RETURN_VALUE=$?
    echo "The exit code of [process_unload] function is $RETURN_VALUE."
}
# 因为process_unload函数完全实现miredo_unload功能，所以本函数弃置！
# 本函数实现如果miredo正在运行，就卸载掉miredo的功能
function miredo_unload() {
    ## 注意：使用通用的带参状态函数，就不必每次需要进程状态，都写一个函数了
    process_status miredo
    echo "v_process_status=$v_process_status"
    if [ $v_process_status == 1 ] ; then
        echo "Already $process_status_processname"
        echo "准备卸载miredo!"
        sudo pkill -9 miredo
        echo “等待1秒，以便{Miredo}卸载完成。”
        sleep 1  #等待3秒，以便卸载完成。
        echo "miredo has been batch killed"

    else
        echo "$process_status_processname not run!"
    fi

    RETURN_VALUE=$?
    echo "The exit code of [miredo_unload] function is $RETURN_VALUE."
}

# 本函数实现如果kext没有运行，就运行的功能
function kext_load() {
    # 也是没有成功也是继续，直到成功为止。
    while true; do

        ## 注意：使用通用的带参状态函数，就不必每次需要进程状态，都写一个函数了
        kext_status "$1"
        echo "v_kext_status=$v_kext_status"
        if [ $v_kext_status == 0 ] ; then

            #运行进程
            echo "运行 $kext_status_kextname 进程！"

            echo "\$\1=$1"
            echo "\$\2=$2"
            # sudo kextload /Applications/Tunnelblick.app/Contents/Resources/tun-signed.kext
            sudo kextload "$2$1"
            echo “等待1秒，以便 [$1]  加载完成。”
            sleep 1  #等待1秒，以便tun-signed加载完成。
            echo "$1 has loaded!"
            echo "$1 加载完成！"

        elif [ $v_kext_status == 1 ] ; then
            echo "Already $kext_status_kextname"
            echo "$kext_status_kextname is loaded! not need to load"
            echo "进程 [$kext_status_kextname] 运行中！无需重新加载"
        else
            echo "未知错误，请检查！"
        fi

        RETURN_VALUE=$?
        echo "The exit code of [kext_load] function is $RETURN_VALUE."

        break
    done
}

# 本函数实现如果process没有运行，就运行的功能，是通用的加载进程的函数
function process_load() {

    # 也是没有成功也是继续，直到成功为止。
    while true; do

        ## 注意：使用通用的带参状态函数，就不必每次需要进程状态，都写一个函数了
        process_status "$1"
        echo "v_process_status=$v_process_status"

        # if [ $v_process_status == 1 ] ; then
        #     echo "Already $process_status_processname"
        #     echo "准备卸载$1!"

        #     # sudo kextunload -b $i
        #     sudo pkill -9 "$1"
        #     echo “等待1秒，以便{$1}卸载完成。”
        #     sleep 1  #等待1秒，以便卸载完成。
        #     echo "$1 has been batch killed"

        # else
        #     echo "$process_status_processname not run! not need unload"
        #     echo "PIDS[Miredo.*]未发现进程["$PIDS"]！"
        # fi

        if [ $v_process_status == 0 ] ; then

           #运行进程
           echo "运行 $process_status_processname 进程,后续增加指定的配置文件！"

           echo "\$\1=$1"
           ##########   echo ""\$\2=$2"  --关于错误要耐心，同时一定要专注加专心，也许一个小错误，会导致严重后果……。。。
           echo "\$\2=$2"
           # sudo "$1" -r "$2" 不能用本办法     # /opt/local/sbin/miredo
           sudo "$2$1"
           echo "$process_status_processname is runing now"

        elif [ $v_process_status == 1 ] ; then
            echo "$process_status_processname is running! not need load"
            echo "进程 [$process_status_processname] 运行中！无需重新加载"
        else
            echo "未知错误，请检查！"
        fi

        RETURN_VALUE=$?
        echo "The exit code of [process_load] function is $RETURN_VALUE."

        break
    done
}


# 因为miredo在加载时要判断net.tunnelblick.tun是否加载，有其特殊性，所以另外增加这个函数来处理
function miredo_load() {

    # 也是没有成功也是继续，直到成功为止。
    while true; do

        ## 注意：使用通用的带参状态函数，就不必每次需要进程状态，都写一个函数了
        process_status "$1"
        echo "v_process_status=$v_process_status"

        if [ $v_process_status == 0 ] ; then

            echo "加载miredo之前，需要判断 net.tunnelblick.tun 或者 net.sf.tuntaposx.*[tun和tap] 是否运行，如果没有需要先运行其中一项。"

            echo "用kext_status来判断net.tunnelblick.tun当前状态"
            echo "显示net.tunnelblick.tun加载信息"
            kext_status net.tunnelblick.tun
            if [ $v_kext_status == 0 ] ; then
                
                echo "$kext_status_kextname is not loaded"
                echo "需要判断 net.sf.tuntaposx.* 是否运行。"

                tuntaposx_status

                if [ $tuntaposx_tun == 1 -a $tuntaposx_tap == 1 ] ; then
                    echo "[miredo_load]net.sf.tuntaposx.*]正在运行中！"
                    
                    ### unset v_kext_status
                    ### unset kext_status_kextname

                    v_kext_status=$tuntaposx_tun
                    kext_status_kextname="net.sf.tuntaposx.*"
                else
                    echo "[miredo_load]net.sf.tuntaposx.*]也未发现运行中！"
                fi

            fi

            if [ $v_kext_status == 1 ] ; then
                # echo "$kext_status_kextname is loaded"
                # echo "显示 $kext_status_kextname 加载信息"
                # kextstat | grep $kext_status_kextname | awk '{print $1"_"$6}'

                echo "$kext_status_kextname is loaded, miredo can be loaded"
                echo "$kext_status_kextname 已加载, miredo可以加载"
           
                echo "\$\1=$1"
                echo "\$\2=$2"
                echo "\$\3=$3"
                #运行进程
                echo "运行Miredo进程,后续增加指定的配置文件！"
                sudo "$2$1" "$3"          # /opt/local/sbin/miredo
                echo "miredo is runing now"
            else
                echo "$kext_status_kextname is not loaded"
            fi

        else
            echo "$process_status_processname is running! not need load"
            echo "进程 [$process_status_processname] 运行中！无需重新加载"
        fi

        RETURN_VALUE=$?
        echo "The exit code of [miredo_load] function is $RETURN_VALUE."

        break
    done
}


# 是否要判断miredo已加载,XX-Net是可以独立运行，但miredo没有运行，或者未连接有效的teredo服务器，则XX-Net也是无法使用
function xxnet_load() {
    echo "xxnet_load:\$1=$1"
    echo "xxnet_load:\$2=$2"
    # 也是没有成功也是继续，直到成功为止。
    while true; do

        max=10
        min=1
        # max=10  # 前面已设，不用再设
        process_status miredo
        while [ $v_process_status == 0 -a $min -le $max ] ; do
            echo "process_status miredo:\$min=$min"
            echo "Miredo not run! 请等待! 等待次数：$min!"
            process_status miredo
            echo "等待10秒！"
            sleep 10

            min=`expr $min + 1`
        done

        if [ $v_process_status == 1 ] ; then
            echo "Already $process_status_processname!"
            echo "[Miredo]已运行中！等待次数: $min"
        else
            echo "[Miredo]尚未运行！请检查原因！等待次数: $min"
            echo "估计系统有问题，请手动启动Miredo！Thinks! "
            break
        fi
        # 设置一个配置文件，来保存XX-Net的目录，然后从配置文件来读取目录位置
        # 如果要重置所有的设置，就运行下面的语句
        if [ "$2" == "reset_all" ] ; then
	    echo "初始化XX-Net数据！"	
            sudo rm -f /softwares/XX-Net/XX-Net-3.12.11/data/gae_proxy/good_ip.txt
            sudo rm -rf /softwares/XX-Net/XX-Net-3.12.11/data/gae_proxy/certs
            sudo rm -f /softwares/XX-Net/XX-Net-3.12.11/data/gae_proxy/Certkey.pem
            sudo rm -f /softwares/XX-Net/XX-Net-3.12.11/data/gae_proxy/CAkey.pem
            sudo rm -f /softwares/XX-Net/XX-Net-3.12.11/data/gae_proxy/CA.crt
        fi

	min=0
	max=300
        # max=10  # 前面已设，不用再设
        process_status Python
        while [ $v_process_status == 0 -a $min -le $max ] ; do
            echo "\$min = $min"
            echo "XX-Net not run! 请等待! 等待次数：$min!"
            # /softwares/XX-Net/XX-Net-3.12.11/start ; exit;            
	    exec /softwares/XX-Net/XX-Net-3.12.11/start
	    echo "XX-Net启动中，已等待 $min 次"
	    echo "XX-Net启动中，此时等待30秒"
	    sleep 30
	    process_status Python
            min=`expr $min + 1`
        done

        if [ $v_process_status == 1 ] ; then
            echo "Already $process_status_processname!"
            echo "[XX-Net]已运行中！等待次数: $min"
        else
            echo "[XX-Net]尚未运行！请检查原因！等待次数: $min"
            echo "估计系统有问题，请手动启动XX-Net！Thinks! "
        fi

        break
    done
}

# 本函数实现如果kext重新加载的功能
function kext_reload() {
    echo "\$\1=$1"
    echo "\$\2=$2"
    # 也是没有成功也是继续，直到成功为止。
    while true; do
        kext_unload "$1"
        kext_load "$1" "$2" "$3"
        break
    done
}


# 本函数实现如果process重新加载的功能
function process_reload() {
    echo "\$\1=$1"
    echo "\$\2=$2"
    # 也是没有成功也是继续，直到成功为止。
    while true; do
        process_unload "$1"
        process_load "$1" "$2" "$3"
        break
    done
}

# 因为miredo进程运行前，要判断tun是否运行，所以另写一个函数实现miredo重新加载的功能
function miredo_reload() {
    echo "\$\1=$1"
    echo "\$\2=$2"
    # 也是没有成功也是继续，直到成功为止。
    while true; do
        process_unload "$1"
        miredo_load "$1" "$2" "$3"
        break
    done
}

# 因为miredo进程运行前，要判断tun是否运行，所以另写一个函数实现miredo重新加载的功能
function xxnet_reload() {
    echo "xxnet_reload:\$1=$1"
    echo "xxnet_reload:\$2=$2"
    # 也是没有成功也是继续，直到成功为止。
    while true; do
        xxnet_unload "$1"
        xxnet_load "$1" "$2"
        break
    done
}

# 因为XX-Net与Miredo是相对独立，但最好还是要判断Miredo是否运行，所以另写一个函数实现XX-Net重新加载的功能
function xxnet_unload() {
    echo "xxnet_unload:\$1=$1"
    echo "xxnet_unload:\$2=$2"

    echo "1. 判断XX-Net是否运行中，如果运行就kill掉。"
    process_status Python

    # 也是没有成功也是继续，直到成功为止。
    while true; do

        # 如果运行中，就卸载。
        echo "xxnet_unload:v_process_status=$v_process_status"
        if [ $v_process_status == 1 ] ; then
            echo "Already XX-Net!"
            echo "准备卸载 XX-Net!"
            sudo pkill -9 "$process_status_processname"
            echo “等待1秒，以便 XX-Net 卸载完成。”
            sleep 1  #等待1秒，以便卸载完成。
            echo "XX-Net has been batch killed"
        else
            echo "XX-Net do not run! not need unload"
        fi

	break
    done
}


echo "\$1=$1"
echo "\$2=$2"

echo "\$3=$3"

# sudo rm -f /var/log/XX-Net*

if [ "$1" != "reload_xxnet" ] ; then
    #### 自动启动miredo进程    ####
    echo " --------------------------"
    echo "|*** 自动启动miredo进程*** |"
    echo " --------------------------"
    # 1. 因为，有安装了tuntaposx，而最终要用Tunnelblick的，所以，
    #    要先判断 net.tuntaposx.tun 和 net.tuntaposx.tap是否已启动,
    #    如果未启动，等待两个启动完成。
    #    方法：用while 或 for loop的方式：如果未启动，则循环，直到启动完成。
    #    参考：Bash-Beginners-Guide.pdf
    #          Chapter 9. Repetitive tasks
    #          9.2. The while loop
    # 2. 启动完成，执行kill，注：如果没有启动完成先执行kill，会导致没有kill掉。
    
    # 注意，跳出循环的技巧:)

    echo "1. 判断tuntaposx.tun 和 tuntaposx.tap是否有启动，如果启动状态，就Kill掉。"
    echo "2. 接着启动tunnelblick的tun。"
    # echo "3. 如果tunnelblick的tun启动成功，再启动miredo。"
    # echo "4. 最后，启动XX-Net。”

fi

echo "开始时间：$(date +%Y-%m-%d\ %H:%M:%S)"
while true; do

    if [ "$1" == "startup" ] ; then
        max=10
    
        kext_status net.tunnelblick.tun
        if [ $v_kext_status == 1 ]; then
            echo "Already net.tunnelblick.tun"
           
            # 设置一个标签变量，说明是 重启的模式，不是开机启动的模式，
	    # 标识：net.tunnelblick.tun是否已启动，如果是启动状态，说明不是开机启动的。
    	    # 目的：因为开机启动的时候，我们系统是会启动net.sf.tuntaposx.*，
	    # 因为net.sf.tuntaposx.*不稳定，所以不用net.sf.tuntaposx.*。
	    # 而用net.tunnelblick.tun，因此，开机后，系统进程只有net.tunnelblick.tun，
	    # 没有net.sf.tuntaposx.*。可以用这个标准判断系统当前是否已是工作状态了。
            v_process_startup_flag="restart"
    
            # 用process_status和process_unloaded的方式
            # 注：根据miredo_unload函数，不用写那么多，直接process_unload miredo 即可！
            process_status miredo
            if [ $v_process_status == 1 ] ; then
                echo "Already $process_status_processname, should be unloaded before net.tunnelblick.tun unloaded"
                process_unload miredo
            else
                echo "Miredo not run! so net.tunnelblick.tun can be unloaded"
            fi  
     
            PIDS=`kextstat | grep net.tunnelblick.tun |grep -v grep | awk '{print $6}'`
            for j in $PIDS; do
                echo "PIDS[net.tunnelblick.*]:$j"
                kext_unload net.tunnelblick.tun 
            done
     
            min=1
    
    	    while [ $v_kext_status == 1 -a $min -le $max ] ; do
                # 再判断一次tuntaposx进程是否都已kill掉了
                echo $min
                kext_status net.tunnelblick.tun
      	        min=`expr $min + 1`
            done
     
            if [ $v_kext_status == 0 ] ; then
                echo "PIDS[net.tunnelblick.tun] 已卸载！等待次数: $min"
                echo "[$j] 已经卸载完成! 接着重新加载[$j]"
            else
                echo "PIDS[net.tunnelblick.tun]无法卸载！请检查原因！等待次数: $min"
                echo "估计系统有问题，请手动启动Miredo！Thinks! "
                break
            fi
     
        else
            echo "PIDS[net.tunnelblick.tun.*]未发现进程！"
        fi
    
    
        if [ "$v_process_startup_flag" != "restart" ]; then
    
    
            min=1
            # max=10  # 前面已设，不用再设
 
            PIDS=`kextstat | grep net.sf.tuntaposx |grep -v grep | awk '{print $6}'`
 	    while [ "$PIDS" == "" -a $min -le $max ] ; do
                echo "PIDS[net.sf.tuntaposx.*]尚未启动，请耐心等候！等待次数: $min"
                echo $min
        	PIDS=`kextstat | grep net.sf.tuntaposx |grep -v grep | awk '{print $6}'`
                min=`expr $min + 1`
            done
        
            if [ "$PIDS" == "" ] ; then
                echo "PIDS[net.sf.tuntaposx.*]尚未启动，等待结束！等待次数: $min"
                echo "估计系统有问题，请手动启动Miredo！Thinks! "
                break
            else
                echo "PIDS[net.sf.tuntaposx.*]: $PIDS 已启动，等待结束！"
        
                process_status miredo
                if [ $v_process_status == 1 ] ; then
                    echo "Already Miredo, should be unloaded before tuntaposx_tun and tuntaposx_tap unloaded"
                    process_unload miredo
                else
                    echo "Miredo not run! so tuntaposx_tun and tuntaposx_tap can be unloaded"
                fi
        
        	for i in $PIDS; do
                    echo "PIDS[net.sf.tuntaposx.*]:$i"
                    kext_unload $i
                done
            fi
        
            # 再判断一次tuntaposx进程是否都已kill掉了
            # PIDS=`kextstat | grep net.sf.tuntaposx |grep -v grep | awk '{print $6}'`
        
            min=1
            # max=10  # 前面已设，不用再设
           
	    PIDS=`kextstat | grep net.sf.tuntaposx |grep -v grep | awk '{print $6}'`
            while [ "$PIDS" != "" -a $min -le $max ] ; do
        	    # 再判断一次tuntaposx进程是否都已kill掉了
                echo $min
                PIDS=`kextstat | grep net.sf.tuntaposx |grep -v grep | awk '{print $6}'`
                min=`expr $min + 1`
            done
        
            if [ "$PIDS" == "" ] ; then
                echo "PIDS[net.sf.tuntaposx.*]已卸载！等待次数: $min"
            else
                echo "PIDS[net.sf.tuntaposx.*]无法卸载！请检查原因！等待次数: $min"
                echo "估计系统有问题，请手动启动Miredo！Thinks! "
                break
            fi
    
        fi
    
        ## 备注：原先开头的 net.tunnelblick.tun 的卸载部分是放在这的！放到开头才能实现重启的功能！
        ## kext_status net.tunnelblick.tun
    
    
        kext_load tun-signed.kext /Applications/Tunnelblick.app/Contents/Resources/

        min=1
        # max=10  # 前面已设，不用再设
        echo "first_v_kext_status: $v_kext_status"
        kext_status net.tunnelblick.tun
        echo "second_v_kext_status: $v_kext_status"
	while [ $v_kext_status == 0 -a $min -le $max ] ; do
                # 再判断一次net.tunnelblick.tun进程是否都已启动了
            echo $min
            kext_status net.tunnelblick.tun
            min=`expr $min + 1`
        done

        if [ $v_kext_status == 1 ] ; then
            echo "PIDS[$kext_status_kextname] 已加载完成！等待次数: $min"
            echo "[$kext_status_kextname 已经加载完成! 接着加载[Miredo]"
        else
            echo "PIDS[$kext_status_kextname]无法加载！请检查原因！等待次数: $min"
            echo "估计系统有问题，请手动启动Miredo！Thinks! "
            break
        fi





        kext_load tap-signed.kext /Applications/Tunnelblick.app/Contents/Resources/

        min=1
        # max=10  # 前面已设，不用再设
        echo "first_v_kext_status: $v_kext_status"
        kext_status net.tunnelblick.tap
        echo "second_v_kext_status: $v_kext_status"
        while [ $v_kext_status == 0 -a $min -le $max ] ; do
                # 再判断一次net.tunnelblick.tap进程是否都已启动了
            echo $min
            kext_status net.tunnelblick.tap
            min=`expr $min + 1`
        done

        if [ $v_kext_status == 1 ] ; then
            echo "PIDS [$kext_status_kextname] 已加载完成！等待次数: $min"
            echo "[$kext_status_kextname 已经加载完成! 接着加载[Miredo]"
        else
            echo "PIDS[$kext_status_kextnamenet]无法加载！请检查原因！等待次数: $min"
            echo "估计系统有问题，请手动启动Miredo！Thinks! "
            break
        fi





        while true; do

           miredo_load miredo /opt/local/sbin/ "$2"
           echo "Miredo已成功运行！"
	   break  # 退出Miredo，应该放这！

        done
        
	# 如下方式不能启动XX-Net，原因不明
	# exec /Users/jennywang/Documents/Notes/00_InstallAndConf/Apple/MacOS/testautostartupmiredo.sh reload_xxnet Python reset_all
	
	echo "都已成功运行，退出！" 
        echo "结束时间：$(date +%Y-%m-%d\ %H:%M:%S)"

	break  # 都成功后，最后退出，应该放这！

    elif [ "$1" == "reload_all" ] ; then
    
        PIDS=`kextstat | grep net.sf.tuntaposx |grep -v grep | awk '{print $6}'`
       # echo "PIDS[net.sf.tuntaposx.*]:$PIDS" # --因为是多个，用下面的方式，不用这个！ 
        if [ "$PIDS" != "" ]; then
            echo "Already tuntaposx_tun and tuntaposx_tap"
    
            # 注：根据miredo_unload函数，不用写那么多，直接process_unload miredo 即可！
            process_status miredo
            if [ $v_process_status == 1 ] ; then
                echo "Already Miredo, should be unloaded before tuntaposx_tun and tuntaposx_tap unloaded"
                process_unload miredo
            else
                echo "Miredo not run! so tuntaposx_tun and tuntaposx_tap can be unloaded"
            fi
    
            for i in $PIDS; do
                echo "PIDS[net.sf.tuntaposx.*]:$i"
    	        sudo kextunload -b $i
    	        echo “等待1秒，以便{$i}卸载完成。”
    	        sleep 1  #等待1秒，以便卸载完成。
            done
        else
            echo "PIDS[net.sf.tuntaposx.*]未发现进程！"
        fi
    
        # 再判断一次tuntaposx进程是否都已kill掉了
        PIDS=`kextstat | grep net.sf.tuntaposx |grep -v grep | awk '{print $6}'`
    
        if [ "$PIDS" == "" ]; then
            PIDS=`kextstat | grep net.tunnelblick.tun |grep -v grep | awk '{print $6}'`
    
            if [ "$PIDS" != "" ]; then
                echo "Already net.tunnelblick.tun"
    
                # 用process_status和process_unloaded的方式
                # 注：根据miredo_unload函数，不用写那么多，直接process_unload miredo 即可！
                process_status miredo
                if [ $v_process_status == 1 ] ; then
                    echo "Already $process_status_processname, should be unloaded before tuntaposx_tun and tuntaposx_tap unloaded"
                    process_unload miredo
                else
                    echo "Miredo not run! so tuntaposx_tun and tuntaposx_tap can be unloaded"
                fi
    
                for j in $PIDS; do
                    echo "PIDS[net.tunnelblick.*]:$j"
                    sudo kextunload -b $j
                    echo “等待1秒，以便{$j}卸载完成。”
                    sleep 1  #等待3秒，以便卸载完成。
                    echo "[$j] has unloaded!"
                    echo "[$j] 已经卸载完成! 接着重新加载[$j]"
                done
            else
                echo "PIDS[net.tunnelblick.tun.*]未发现进程！"
            fi
    
            # 再判断一次tunnelblick进程是否都已kill掉了
            PIDS=`kextstat | grep net.tunnelblick.tun |grep -v grep | awk '{print $6}'`
    
    	if [ "$PIDS" == "" ]; then
                sudo kextload /Applications/Tunnelblick.app/Contents/Resources/tun-signed.kext
                echo “等待1秒，以便tun-signed加载完成。”
                sleep 1  #等待1秒，以便tun-signed加载完成。
                echo "tun-signed.kext has loaded!"
                echo "tun-signed加载完成，接着加载Miredo！"
                # 备注：运行Miredo，做一个function 比较合适，不要一古脑的写下去，代码就显得比较臃肿，没有章法。
                # 另：tun的部分，与miredo相同或相关的功能也是可以写成一个函数或新的.sh文件（java中可以是类或方法）
    
    
                # 此时判断一下tunnelblick进程是否运行起来了，也用循环来处理
    	        while true; do
    
                    echo "加载Miredo之前，先验证下net.tunnelblick.tun是否已加载！"
                    PIDS=`kextstat | grep net.tunnelblick.tun |grep -v grep | awk '{print $6}'`
    
                    if [ "$PIDS" != "" ]; then
                        echo "Already net.tunnelblick.tun" # 说明net.tunnelblick.tun已运行,可运行Miredo了
                        miredo_load miredo /opt/local/sbin/ "$2"
                        echo "Miredo已成功运行！"
                        break  # 退出Miredo，应该放这！
                    else
                        echo "未知错误！"
                    fi
    
    
                done
    
                echo "都已成功运行，退出！"
                echo "完成时间：$(date +%Y-%m-%d\ %H:%M:%S)"
                break  # 都成功后，最后退出，应该放这！
    
            fi
        fi
    elif [ "$1" == "reload_miredo" ] ; then
        echo "仅重启Miredo"
    
        miredo_reload miredo /opt/local/sbin/ "$2"
        ./testautostartupmiredo.sh status
        echo "reload_miredo:完成时间：$(date +%Y-%m-%d\ %H:%M:%S)"
        break
    elif [ "$1" == "reload_xxnet" ] ; then
        echo "仅重启XX-Net"

	echo "reload_xxnet:\$1=$1"	
	echo "reload_xxnet:\$1=$1"
        #  echo "reload_xxnet:\$3=$3"
        #### 自动启动XX-Net进程    ####
        echo " --------------------------"
        echo "|*** 自动启动XX-Net进程*** |"
        echo " --------------------------"
        echo "XX-Net:开始时间：$(date +%Y-%m-%d\ %H:%M:%S)"

	xxnet_reload "$2" "$3" # 其中:"$2"="Python" "$3"="reset_all" 
        
	echo "XX-Net:完成时间：$(date +%Y-%m-%d\ %H:%M:%S)"
        break
    elif [ "$1" == "status" ] ; then
    
        PIDS=`kextstat | grep net.sf.tuntaposx |grep -v grep | awk '{print $6}'`
       # echo "PIDS[net.sf.tuntaposx.*]:$PIDS" # --因为是多个，用下面的方式，不用这个！
        if [ "$PIDS" != "" ]; then
            echo "<status:>Already tuntaposx_tun and tuntaposx_tap"
            for i in $PIDS; do
                echo "<status:>PIDS[net.sf.tuntaposx.*]:$i"
            done
        else
            echo "status:PIDS[net.sf.tuntaposx.*]未发现进程！"
        fi
    
        # echo "显示net.tunnelblick.tun加载信息"
        # kextstat | grep net.tunnelblick.tun | awk '{print $1"_"$6}'
        # echo "显示miredo进程信息"
        # pgrep -l miredo
    
        echo "用kext_status来判断net.tunnelblick.tun当前状态"
        echo "显示net.tunnelblick.tun加载信息"
        kext_status net.tunnelblick.tun
        # if [ $v_kext_status == 1 ] ; then
        #     echo "$kext_status_kextname is loaded"
        #     echo "显示 $kext_status_kextname 加载信息"
        #      kextstat | grep $kext_status_kextname | awk '{print $1"_"$6}'
        # else
        #     echo "$kext_status_kextname is not loaded"
        # fi
    
        echo "用process_status来判断Miredo当前状态"
        echo "显示Miredo加载信息"
        process_status miredo
        if [ $v_process_status == 1 ] ; then
            echo "$process_status_processname is running"
            echo "显示 $process_status_processname 进程信息"
            pgrep -l $process_status_processname
        else
            echo "$process_status_processname is not running"
        fi      
    
        echo "Teredo的服务器速度测试"
        echo "后续要根据测试结果，来更换服务器"
        python /softwares/XX-Net/XX-Net-3.12.11/code/default/gae_proxy/local/ipv6_tunnel/pteredor.py
    
        # echo "以下仅显示Teredo服务器IP Address信息"
        # python /softwares/XX-Net/XX-Net-3.12.11/code/default/gae_proxy/local/ipv6_tunnel/pteredor.py | awk '{print $1}'
    
        ### 不能用！！！###
        # TeredoIPS=`python /softwares/XX-Net/XX-Net-3.12.11/code/default/gae_proxy/local/ipv6_tunnel/pteredor.py | awk '{print $1}'`
        # echo $TeredoIPS
    
        break
    else
        echo "Run $0 <reload_all|reload_tunnelblick|reload_miredo|status>"
        echo "时间：$(date +%Y-%m-%d\ %H:%M:%S)"
	break
    fi

done

exit
