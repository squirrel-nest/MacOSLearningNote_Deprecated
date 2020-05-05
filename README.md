# MacOSLearningNote
## System Administration Refer to [MacOSSystemLearningNote.md](https://github.com/squirrel-nest/MacOSLearningNote/blob/master/MacOSSystemLearningNote.md)<br>

## Terminal 的 设置
   * 参考 - English
      + [Random Terminal Background Colors](https://scriptingosx.com/2019/12/random-terminal-background-colors/)<br>
      + [How To Customize Your macOS Terminal](https://medium.com/@charlesdobson/how-to-customize-your-macos-terminal-7cce5823006e)<br>
      + [How to Improve the Terminal Appearance in macOS?](https://osxtips.net/how-to-improve-the-terminal-in-macos/)<br>
   * 参考 - 中文
      + 
   * 基本设置
      + 步骤
         1. 切换到主用户目录：
            - ```bash
                  cd ~
              ```
         2. 编辑.bash_profile文件：
            - ```bash
                  vim .bash_profile
              ```
         3. 按 i 进入插入模式，在文件末尾添加如下代码：
            - ```bash
                  #export LS_OPTIONS='--color=auto'           # 如果没有指定，则自动选择颜色
                  export CLICOLOR='Yes'                       # 是否输出颜色
                  export LSCOLORS='ExGxFxdaCxDaDahbadacec'    # 指定颜色
              ```
         4. 按Esc退出到命令模式，输入 :wq 保存退出，然后应用新的配置：
            - ```bash
                  source .bash_profile
              ```
         5. 关闭当前Terminal，重启一个新的Terminal使配置生效。
            - ![Terminal_Bash](https://blog.csdn.net/u010391437/article/details/75126310)<br>
