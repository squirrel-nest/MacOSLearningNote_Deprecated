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
# 无法筛选进程，故弃置!
function miredo_status() {
    ps -ef | grep miredo | grep -v grep > /dev/null 2>&1 ;
    v_miredo=$((1-$?))
}

# 本函数实时获取miredo进程当前是否运行, =1为运行状态，=0为非运行状态
function miredo_status_new() {
    # pgrep -l miredo | awk '{print $1}' > /dev/null 2>&1 ; # -- 不能用这句！
    pgrep -l miredo > /dev/null 2>&1 ;
    v_miredo_status=$((1-$?))

    miredo_status_processname="Miredo"

    RETURN_VALUE=$?
    echo "The exit code of this function is $RETURN_VALUE."
}

# 传入参数形式：kext_status net.sf.tuntaposx.tun
function kext_status() {
    kextstat | grep "$1" > /dev/null 2>&1 ;
    v_kext_status=$((1-$?))

    kext_status_kextname=$1

    RETURN_VALUE=$?
    echo "The exit code of [kext_status] function is $RETURN_VALUE."
}

# 本函数实时获取通用进程当前是否运行, =1为运行状态，=0为非运行状态
# 用参数传递进程名，就不用每个进程都写一个函数了！
function process_status() {
    # 注意：PIDS这个变量已在全局用，而函数中也是会影响到全局变量的值，故这里就要另起变量名。
    PIDS_process_status=`pgrep -l $1 | awk '{print $1}'`
    echo "PIDS_process_status:["$PIDS_process_status"]！"
    # pgrep -l "$1" | awk '{print $1}' > /dev/null 2>&1 ; # -- 不能用这句！
    pgrep -l "$1" > /dev/null 2>&1 ;
    v_process_status=$((1-$?))

    process_status_processname=$1

    RETURN_VALUE=$?
    echo "The exit code of [process_status] function is $RETURN_VALUE."
}

test ()
{
echo "Positional parameter 1 in the function is $1."
RETURN_VALUE=$?
echo "The exit code of this function is $RETURN_VALUE."
}

# 本函数实现如果miredo正在运行，就卸载掉miredo的功能
function miredo_unload() {
    ## 注意：使用通用的带参状态函数，就不必每次需要进程状态，都写一个函数了
    process_status miredo
    echo "v_process_status=$v_process_status"
    if [ $v_process_status == 1 ] ; then
        echo "Already $process_status_processname"
        echo "准备卸载miredo!"
        sudo pkill -9 miredo
        echo “等待3秒，以便{Miredo}卸载完成。”
        sleep 3  #等待3秒，以便卸载完成。
        echo "miredo has been batch killed"

    else
        echo "$process_status_processname not run!"
    fi

    RETURN_VALUE=$?
    echo "The exit code of this function is $RETURN_VALUE."
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
        echo “等待3秒，以便{$1}卸载完成。”
        sleep 3  #等待3秒，以便卸载完成。
        echo "$1 has been batch killed"

    else
        echo "$process_status_processname not run! not need unload"
    fi

    RETURN_VALUE=$?
    echo "The exit code of this function is $RETURN_VALUE."
}

# 本函数实现如果process正在运行，就卸载掉的功能
function kext_unload() {
    ## 注意：使用通用的带参状态函数，就不必每次需要进程状态，都写一个函数了
    kext_status "$1"
    echo "v_kext_status=$v_kext_status"
    if [ $v_kext_status == 1 ] ; then
        echo "Already $kext_status_kextname"
        echo "准备卸载$1!"
        # sudo pkill -9 "$1"
        sudo kextunload -b $1
        echo “等待3秒，以便{$1}卸载完成。”
        sleep 3  #等待3秒，以便卸载完成。
        echo "$1 has been unloaded"

    else
        echo "$process_status_processname not run! not need unload"
    fi

    RETURN_VALUE=$?
    echo "The exit code of this function is $RETURN_VALUE."
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
        #     echo “等待3秒，以便{$1}卸载完成。”
        #     sleep 3  #等待3秒，以便卸载完成。
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

            echo "加载miredo之前，需要判断 net.tunnelblick.tun 是否运行，如果没有需要先运行。"

            echo "用kext_status来判断net.tunnelblick.tun当前状态"
            echo "显示net.tunnelblick.tun加载信息"
            kext_status net.tunnelblick.tun
            if [ $v_kext_status == 1 ] ; then
                echo "$kext_status_kextname is loaded"
                echo "显示 $kext_status_kextname 加载信息"
                kextstat | grep $kext_status_kextname | awk '{print $1"_"$6}'

                echo "$kext_status_kextname is loaded, miredo can be loaded"
                echo "$kext_status_kextname已加载, miredo可以加载"
           
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
        echo "The exit code of [process_load] function is $RETURN_VALUE."

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


# 不用这个函数了，grep方式筛选有问题
function miredo_run() {

    miredo_status

    # 也是没有成功也是继续，直到成功为止。
    while true; do
        echo "v_miredo:$v_miredo"
        PIDS=`ps -ef |grep miredo |grep -v grep | awk '{print $2 $8}'`
        PSTRINGS=`ps -ef |grep miredo |grep -v grep | awk '{print $8}'`
        if [ "$PIDS" != "" ]; then
            echo "Already Miredo"
            for i in $PIDS; do
                echo "PIDS[Miredo.*]:$i"

                if [ `$PIDS >&1|grep miredo` != "" ]; then
                    # sudo kextunload -b $i
                    echo “等待3秒，以便{$i}卸载完成。”
                    sleep 3  #等待3秒，以便卸载完成。
                else
		    echo "$1:非Miredo进程["$1"]！"
                fi
            done

            # echo "ready to kill process!"
            # for pid in $(ps -ef |grep miredo |grep -v grep | awk '{print $2}'); do sudo kill -9 $pid; done
            # echo "miredo has been batch killed"



        else
            echo "PIDS[Miredo.*]未发现进程["$PIDS"]！"
        fi
        break
    done

}

function miredo_run_new() {

    miredo_status

    # 也是没有成功也是继续，直到成功为止。
    while true; do
        echo "v_miredo:$v_miredo"
        PIDS=`pgrep -l miredo | awk '{print $1}'`
        if [ "$PIDS" != "" ]; then
            echo "Already Miredo"

            # sudo kextunload -b $i
            sudo pkill -9 miredo
            echo “等待3秒，以便{Miredo}卸载完成。”
            sleep 3  #等待3秒，以便卸载完成。
            echo "miredo has been batch killed"
        else
            echo "PIDS[Miredo.*]未发现进程["$PIDS"]！"
        fi
        
        PIDS=`pgrep -l miredo | awk '{print $1}'`
        if [ "$PIDS" == "" ]; then
            #运行进程
            echo "运行Miredo进程,后续增加指定的配置文件！"
            sudo /opt/local/sbin/miredo
            echo "miredo is runing now"
        fi
        break
    done

}

### 这两个测试用
### miredo_run ### 不用这个不好筛选进程。###
### miredo_run_new
miredo_status_new

echo "v_miredo_status=$v_miredo_status"
if [ $v_miredo_status == 1 ] ; then
    echo "Already Miredo"
else
    echo "Miredo not run!"
fi

test miredo
process_status miredo
echo "v_process_status=$v_process_status"
if [ $v_process_status == 1 ] ; then
    echo "Already $process_status_processname"
else
    echo "$process_status_processname not run!"
fi


tuntaposx_status
echo "\$\1=$1"
echo "\$\2=$2"
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
while true; do

echo "1. 判断tuntaposx.tun 和 tuntaposx.tap是否有启动，如果启动状态，就Kill掉。"
echo "2. 接着启动tunnelblick的tun。"
# echo "3. 如果tunnelblick的tun启动成功，再启动miredo。"
# echo "4. 最后，启动XX-Net。”

if [ "$1" == "reload_all" ] ; then

    PIDS=`kextstat | grep net.sf.tuntaposx |grep -v grep | awk '{print $6}'`
   # echo "PIDS[net.sf.tuntaposx.*]:$PIDS" # --因为是多个，用下面的方式，不用这个！ 
    if [ "$PIDS" != "" ]; then
        echo "Already tuntaposx_tun and tuntaposx_tap"

        # miredo_status_new
        # if [ $v_miredo_status == 1 ] ; then
        #     echo "Already Miredo, should be unloaded before tuntaposx_tun and tuntaposx_tap unloaded"
        #     miredo_unload
        # else
        #     echo "Miredo not run! so tuntaposx_tun and tuntaposx_tap can be unloaded"
        # fi

        # 用process_status和process_unloaded的方式        
        # 注：根据miredo_unload函数，不用写那么多，直接process_unload miredo 即可！
        process_status miredo
        if [ $v_miredo_status == 1 ] ; then
            echo "Already Miredo, should be unloaded before tuntaposx_tun and tuntaposx_tap unloaded"
            process_unload miredo
        else
            echo "Miredo not run! so tuntaposx_tun and tuntaposx_tap can be unloaded"
        fi

        for i in $PIDS; do
            echo "PIDS[net.sf.tuntaposx.*]:$i"
	    sudo kextunload -b $i
	    echo “等待3秒，以便{$i}卸载完成。”
	    sleep 3  #等待3秒，以便卸载完成。
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

            # miredo_status_new
            # if [ $v_miredo_status == 1 ] ; then
            #     echo "Already Miredo, should be unloaded before net.tunelblick.tun unloaded"
            #     miredo_unload
            # else
            #     echo "Miredo not run! so net.tunelblick.tun can be unloaded"
            # fi

            # 用process_status和process_unloaded的方式
            # 注：根据miredo_unload函数，不用写那么多，直接process_unload miredo 即可！
            process_status miredo
            if [ $v_process_status == 1 ] ; then
                echo "Already Miredo, should be unloaded before tuntaposx_tun and tuntaposx_tap unloaded"
                process_unload miredo
            else
                echo "Miredo not run! so tuntaposx_tun and tuntaposx_tap can be unloaded"
            fi

            for j in $PIDS; do
                echo "PIDS[net.tunnelblick.*]:$j"
                sudo kextunload -b $j
                echo “等待3秒，以便{$j}卸载完成。”
                sleep 3  #等待3秒，以便卸载完成。
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
            echo “等待3秒，以便tun-signed加载完成。”
            sleep 3  #等待3秒，以便tun-signed加载完成。
            echo "tun-signed.kext has loaded!"
            echo "tun-signed加载完成，接着加载Miredo！"
            # 备注：运行Miredo，做一个function 比较合适，不要一古脑的写下去，代码就显得比较臃肿，没有章法。
            # 另：tun的部分，与miredo相同或相关的功能也是可以写成一个函数或新的.sh文件（java中可以是类或方法）


            # 此时判断一下tunnelblick进程是否运行起来了，也用循环来处理
	    while true; do

                PIDS=`kextstat | grep net.tunnelblick.tun |grep -v grep | awk '{print $6}'`

                if [ "$PIDS" != "" ]; then
                    echo "Already net.tunnelblick.tun" # 说明net.tunnelblick.tun已运行,可运行Miredo了
                    echo "加载Miredo之前，先验证下net.tunnelblick.tun是否已加载！"
                    miredo_run_new
                    echo "Miredo已成功运行！"
                    break  # 退出Miredo，应该放这！
                fi


            done

            echo "都已成功运行，退出！" 
            break  # 都成功后，最后退出，应该放这！

        fi
    fi
elif [ "$1" == "reload_miredo" ] ; then
    echo "仅重启Miredo"

    miredo_reload miredo /opt/local/sbin/ "$2"
    ./testautostartupmiredo.sh status
    break
elif [ "$1" == "status" ] ; then
    echo "显示net.tunnelblick.tun加载信息"
    kextstat | grep net.tunnelblick.tun | awk '{print $1"_"$6}'
    echo "显示miredo进程信息"
    pgrep -l miredo

    echo "用kext_status来判断net.tunnelblick.tun当前状态"
    echo "显示net.tunnelblick.tun加载信息"
    kext_status net.tunnelblick.tun
    if [ $v_kext_status == 1 ] ; then
        echo "$kext_status_kextname is loaded"
        echo "显示 $kext_status_kextname 加载信息"
        kextstat | grep $kext_status_kextname | awk '{print $1"_"$6}'
    else
        echo "$kext_status_kextname is not loaded"
    fi

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
    # echo "以下仅显示Teredo服务器信息"
    # python /softwares/XX-Net/XX-Net-3.12.11/code/default/gae_proxy/local/ipv6_tunnel/pteredor.py | awk '{print $1}'
    break
else
    echo "Run $0 <reload_all|reload_tunnelblick|reload_miredo|status>"
    break
fi

done

exit

