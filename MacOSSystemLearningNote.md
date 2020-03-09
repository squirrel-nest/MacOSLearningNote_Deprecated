# MacOS System Learning Note
## 无权限执行操作时的做法
   * way1
      + 用管理员进行操作
      ```
         su
         password:
      ```
   * way2
      + 更改用户权限
      ```   
         chmod [][][]
      ```
   * way3
      + "Read-only file system" 通过苹果官方给出的命令解决
      + [Apple support: Internal Hard Drive Locked "Read Only"](https://discussions.apple.com/thread/4193178)
     ```
        sudo mount -uw /
     ```
   * way4
      + "Operation not permitted" 通过关闭系统rootless来解决
      + 重启并按下command+R进入恢复模式
      + 在恢复模式下打开terminal
      ```
         csrutil disable
      ```
      ⚠️ Rootless机制将成为对抗恶意程序的最后防线，记得要再开起来。
