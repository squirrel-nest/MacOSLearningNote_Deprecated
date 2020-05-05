# MacOS System Learning Note
## 无权限执行操作时的做法
   * way1
      + 用管理员进行操作
      ```vim
         su
         password:
      ```
   * way2
      + 更改用户权限
      ```vim   
         chmod [][][]
      ```
   * way3
      + "Read-only file system" 通过苹果官方给出的命令解决
      + [Apple support: Internal Hard Drive Locked "Read Only"](https://discussions.apple.com/thread/4193178)
     ```vim
        sudo mount -uw /
     ```
   * way4
      + "Operation not permitted" 通过关闭系统rootless来解决
      + 重启并按下command+R进入恢复模式
      + 在恢复模式下打开terminal
      ```vim
         csrutil disable
      ```
      ⚠️ Rootless机制将成为对抗恶意程序的最后防线，记得要再开起来。
## MacOS 15.4 以上版本的alias设置
   ```vim
   1. vim ~/.bashrc
   # 若无，则新建
   2. alias name='command line'
   # 格式
   3. source ~/.bashrc
   # 保存退出后使之生效
   ```
## 当设置完 ~/.bash_profile 重新打开终端需要重新source的解决办法
   * 发现zsh加载的是 ~/.zshrc文件
   * 在 ~/.zshrc 增加需要生效的文件
   ```vim
   source ~/.bash_profile
   source ~/.bashrc
   ```
   
