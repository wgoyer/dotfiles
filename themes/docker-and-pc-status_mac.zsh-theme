autoload -U add-zsh-hook
autoload -Uz vcs_info

setopt promptsubst

zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:git*:*' get-revision true
zstyle ':vcs_info:git*:*' check-for-changes true
zstyle ':vcs_info:git*:*' stagedstr "%F{green}S%F{black}%B"
zstyle ':vcs_info:git*:*' unstagedstr "%F{red}U%F{black}%B"
zstyle ':vcs_info:git*+set-message:*' hooks git-st git-stash git-username

zstyle ':vcs_info:git*' formats "(%s) %12.12i %c%u %b%m" # hash changes branch misc
zstyle ':vcs_info:git*' actionformats "(%s|%F{white}%a%F{black}%B) %12.12i %c%u %b%m"

add-zsh-hook precmd theme_precmd

# Show remote ref name and number of commits ahead-of or behind
function +vi-git-st() {
    local ahead behind remote
    local -a gitstatus

    # Are we on a remote-tracking branch?
    remote=${$(git rev-parse --verify ${hook_com[branch]}@{upstream} \
        --symbolic-full-name --abbrev-ref 2>/dev/null)}

    if [[ -n ${remote} ]] ; then
        ahead=$(git rev-list ${hook_com[branch]}@{upstream}..HEAD 2>/dev/null | wc -l | sed -e 's/^[[:blank:]]*//')
        (( $ahead )) && gitstatus+=( "%F{green}+${ahead}%F{black}%B" )

        behind=$(git rev-list HEAD..${hook_com[branch]}@{upstream} 2>/dev/null | wc -l | sed -e 's/^[[:blank:]]*//')
        (( $behind )) && gitstatus+=( "%F{red}-${behind}%F{black}%B" )

        [[ ${#gitstatus} -gt 0 ]] && gitstatus=" ${(j:/:)gitstatus}"
        hook_com[branch]="${hook_com[branch]} [${remote}${gitstatus}]"
    fi
}

# Show count of stashed changes
function +vi-git-stash() {
    local -a stashes

    if [[ -s ${hook_com[base]}/.git/refs/stash ]] ; then
        stashes=$(git stash list 2>/dev/null | wc -l | sed -e 's/^[[:blank:]]*//')
        hook_com[misc]+=" (${stashes} stashed)"
    fi
}

# Show local git user.name
function +vi-git-username() {
    local -a username

    username=$(git config --local --get user.name | sed -e 's/\(.\{40\}\).*/\1.../')
    hook_com[misc]+=" ($username)"
}

function _get-pr-prompt() {
    source ~/code/prChecka/pr.properties
    local pr_prompt=""
    local reviews="false"
    if [[ ! -z "${jenkins_dsl_jobs_pr_count}" ]]; then
        reviews="true"
        pr_prompt=":%F{green}${jenkins_dsl_jobs_pr_count}%B%F{white}🏗 "
    fi

    if [[ ! -z "${jenkins_docker_pr_count}" ]]; then
        reviews="true"
        pr_prompt="${pr_prompt}:%F{green}${jenkins_docker_pr_count}%B%F{white}🐳"
    fi

    if [[ ! -z "${jenkins_libraries_pr_count}" ]]; then
        reviews="true"
        pr_prompt="${pr_prompt}:%F{green}${jenkins_libraries_pr_count}%B%F{white}📚"
    fi

    if [[ ! -z "${ci_scripts_pr_count}" ]]; then
        reviews="true"
        pr_prompt="${pr_prompt}:%F{green}${ci_scripts_pr_count}%B%F{white}📜"
    fi

    if [[ ! -z "${jc_cli_pr_count}" ]]; then
        reviews="true"
        pr_prompt="${pr_prompt}:%F{green}${jc_cli_pr_count}%B%F{white}📦"
    fi

    if [[ ! -z "${jenkins_cloud_pr_count}" ]]; then
        reviews="true"
        pr_prompt="${pr_prompt}:%F{green}${jenkins_cloud_pr_count}%B%F{white}⛅"
    fi

    if [[ $reviews == "true" ]]; then
        pr_prompt="{👀${pr_prompt}} "
        echo -n "%B%F{white}${pr_prompt}%F{default}"
    fi
}

function _get-docker-prompt() {
    local docker_all=$(docker ps -a --format "{{.Status}}")
    local up_containers=$(echo $docker_all | grep up -i | wc -l | xargs)👌
    local down_containers=$(echo $docker_all | grep exit -i | wc -l | xargs)☠️
    local docker_prompt="%F{green}$up_containers %F{white}:%F{red}${down_containers}"
    echo -n "%B%F{white}🐳 :${docker_prompt}%F{white}  |%F{default} "
}

function setprompt() {
    unsetopt shwordsplit
    local -a lines infoline
    local x i filler i_width

    ### First, assemble the top line
    # Current dir; show in yellow if not writable
    [[ -w $PWD ]] && infoline+=( "%F{green}" ) || infoline+=( "%F{yellow}" )
    infoline+=( "%F{blue}%W|%@ %B%F{white}[%b${PWD/#$HOME/~}%B%F{white}]%b%F{default} " )
    infoline+=( "$(_get-pr-prompt)" )
    if [[ $ENABLE_DOCKER_PROMPT == 'true' ]]; then
        infoline+=( "$(_get-docker-prompt)" )
    fi

    # CPU Usage
    local cpu_use_string cpu_use
    cpu_use=$(top -l 1 | grep "CPU usage:" | awk '{print $5}' | tr -d '%')
    cpu_use_string="%F{yellow}$cpu_use%%%B%F{white}:%b🐇"
    if [[ $cpu_use -lt "25" ]]; then
        cpu_use_string="%F{green}$cpu_use%%%B%F{white}:%b🐢"
    fi
    if [[ $cpu_use -gt "65.001" ]]; then
        cpu_use_string="%F{red}$cpu_use%%%B%F{white}:%b🔥"
    fi

    infoline+=( "💻 %B%F{white}:$cpu_use_string %F{default}%b" )
    [[ -n $SSH_CLIENT ]] && infoline+=( "@%m" )

    i_width=${(S)infoline//(\%F\{*\}|\%b|\%B)} # search-and-replace color escapes
    i_width=${#${(%)i_width}} # expand all escapes and count the chars

    filler="%F{black}%B${(l:$(( $COLUMNS - $i_width - 1))::-:)}%F{default}%b"
    infoline[2]=( "${infoline[2]}${filler} " )

    ### Now, assemble all prompt lines
    lines+=( ${(j::)infoline} )
    [[ -n ${vcs_info_msg_0_} ]] && lines+=( "%F{black}%B${vcs_info_msg_0_}%F{default}%b" )
    lines+=( "%(1j.%F{black}%B%j%F{default}%b .)%(0?.%F{white}.%F{red})%#%F{default} " )

    ### Finally, set the prompt
    PROMPT=${(F)lines}
}


theme_precmd () {
    vcs_info
    setprompt
}
