# Install and configure ***vim*** editor

## Install
``` bash
sudo apt-get install vim
```

<br>

## Configure

For permanent settings, add the commands in the `vimrc` file:
```bash
vim ~/.vimrc
```

### Line Numbers
Enable:
```bash
:set number
```

Disable:
```bash
:set nonumber
```

Toggle:
```bash
:set number!
```

<br>

## Various commands

`i`: *insert* mode<br>
`x`: delete next character<br>
`w`: move forward one  word<br>
`b`: move backwards one  word<br>
`gg`: go to the top of the file<br>
`V`: visual mode<br>
`G`: go to the bottom of the file<br>
`ggVG`: select all<br>
`:%d`: delete every line<br>
`=G`: fix indentation in all document (only if cursor is moved on top)<br>
`S`: start writing on a line at correct indentation<br>
`>` `<`: indent/unindent multiple lines (in visual line mode)<br>
`>>` `<<`: indent/unindent a line<br>
`:tabnew`: creates a new tab<br>
`gt`: go to next tab<br>
`gT`: go to previous tab<br>
`:tabo` close all other tabs besides the active one<br><br>

`:setlocal spell` enable spell check
`:set nospell` disable spell check

<br>

### Search & replace

``` bash
# in the lines 1 to 20, replace the 'search' with the word 'replace'
:1,20 s/search/replace/
```