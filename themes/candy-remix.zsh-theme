PROMPT=$'\n%D{$fg[white][$fg[blue]%X$fg[white]]} %{$fg[white]%}[%{$fg[blue]%}%~$fg[white]%}]%{$reset_color%} $(git_prompt_info)\
%{$fg_bold[blue]%}%#%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[white]%}[%{$fg_bold[green]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$fg[white]%}]%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}*%{$fg[white]%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
