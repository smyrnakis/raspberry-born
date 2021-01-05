# Install *zsh* and configure *oh-my-zsh*

*Article: https://www.seeedstudio.com/blog/2020/03/06/prettify-raspberry-pi-shell-with-oh-my-zsh/*

<br>

### Install and make default

``` bash
sudo apt-get install zsh

chsh -s /bin/zsh
```

### Get and install *oh-my-zsh*

``` bash
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
```

### Change theme to [agnoster](https://github.com/agnoster/agnoster-zsh-theme)

``` bash
nano ~/.zshrc
```

Change the line to:

``` bash
ZSH_THEME="agnoster"
```

More themes available at [https://github.com/ohmyzsh/ohmyzsh/wiki/Themes](https://github.com/ohmyzsh/ohmyzsh/wiki/Themes) .

### Install *autosuggestions* & *syntax-highlighting*

``` bash
git clone git://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

### Extra

Edit the file `~/.zshrc` accordingly:

``` bash
# include the following line to add timestamp
PROMPT='%{%f%b%k%}[%D{%k:%M}] '$PROMPT

# use this for full date-time with yellow color
PROMPT='%{$fg[yellow]%}[%D{%k:%M:%S}] '$PROMPT
```


<!--

Edit the file `.oh-my-zsh/themes/agnoster.zsh-theme` accordingly:

``` bash
# Begin a segment
# [...]

# Add timestamp
prompt_timestamp() {
  prompt_segment NONE default ""
  echo ""
  DATE=$( date +"%H:%M:%S" )
  prompt_segment white black ${DATE}
}

# End the prompt, closing any open segments
[...]
```
-->