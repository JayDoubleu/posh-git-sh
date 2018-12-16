#!/bin/sh

# bash/zsh git prompt support
#
# Copyright (C) 2018 David Xu
#
# Based on the earlier work by Shawn O. Pearce <spearce@spearce.org>
# Distributed under the GNU General Public License, version 2.0.
#
# This script allows you to see the current branch in your prompt,
# posh-git style.
#
# You will most likely want to make use of either `__posh_git_ps1` or
# `__posh_git_echo`. Refer to the documentation of the functions for additional
# information.
#
#
# CONFIG OPTIONS
# ==============
#
# This script should work out of the box. Available options are set through
# your git configuration files. This allows you to control the prompt display on a
# per-repository basis.
# ```
# bash.describeStyle
# bash.enableFileStatus
# bash.enableGitStatus
# bash.showStatusWhenZero
# bash.showUpstream
# ```
#
# bash.describeStyle
# ------------------
#
# This option controls if you would like to see more information about the
# identity of commits checked out as a detached `HEAD`. This is also controlled
# by the legacy environment variable `GIT_PS1_DESCRIBESTYLE`.
#
# Option   | Description
# -------- | -----------
# contains | relative to newer annotated tag `(v1.6.3.2~35)`
# branch   | relative to newer tag or branch `(master~4)`
# describe | relative to older annotated tag `(v1.6.3.1-13-gdd42c2f)`
# default  | exactly matching tag
#
# bash.enableFileStatus
# ---------------------
#
# Option | Description
# ------ | -----------
# true   | _Default_. The script will query for all file indicators every time.
# false  | No file indicators will be displayed. The script will not query
#          upstream for differences. Branch color-coding information is still
#          displayed.
#
# bash.enableGitStatus
# --------------------
#
# Option | Description
# ------ | -----------
# true   | _Default_. Color coding and indicators will be shown.
# false  | The script will not run.
#
# bash.showStashState
# -------------------
#
# Option | Description
# ------ | -----------
# true   | _Default_. An indicator will display if the stash is not empty.
# false  | An indicator will not display the stash status.
#
# bash.showStashCount
# -------------------
#
# Option | Description
# ------ | -----------
# true   | _Default_. The count of refs in stash will also be shown if `bash.showStashState` is true.
# false  | The count of refs in stash will not be shown.
#
# bash.showStatusWhenZero
# -----------------------
#
# Option | Description
# ------ | -----------
# true   | Indicators will be shown even if there are no updates to the index or
#          working tree.
# false  | _Default_. No file change indicators will be shown if there are no
#          changes to the index or working tree.
#
# bash.showUpstream
# -----------------
#
# By default, `__posh_git_ps1` will compare `HEAD` to your `SVN` upstream if it can
# find one, or `@{upstream}` otherwise. This is also controlled by the legacy
# environment variable `GIT_PS1_SHOWUPSTREAM`.
#
# Option | Description
# ------ | -----------
# legacy | Does not use the `--count` option available in recent versions of
#          `git-rev-list`
# git    | _Default_. Always compares `HEAD` to `@{upstream}`
# svn    | Always compares `HEAD` to `SVN` upstream
#
# bash.enableStatusSymbol
# -----------------------

# Option | Description
# ------ | -----------
# true   | _Default_. Status symbols (`≡` `↑` `↓` `↕`) will be shown.
# false  | No status symbol will be shown, saving some prompt length.
#
###############################################################################

# Convenience function to set PS1 to show git status. Must supply two
# arguments that specify the prefix and suffix of the git status string.
# This function should be called in PROMPT_COMMAND or similar.
__posh_git_ps1 ()
{
    PS1="$(__posh_git_echo) %(#.#.$) "

    #local y=$(date "+%s.%N")
    #local gitstring=$(__posh_git_echo)
    #local z=$(date "+%s.%N")
    #echo $(($z - $y))
    #PS1="$gitstring %(#.#.$) "

    #git status --porcelain
}

# Echoes the git status string.
__posh_git_echo () {
    local DefaultForegroundColor=$(echo %{'\e[m'%}) # Default no color
    local DefaultBackgroundColor=

    local BeforeText='['
    local BeforeForegroundColor=$(echo %{'\e[1;33m'%}) # Yellow
    local BeforeBackgroundColor=
    local DelimText=' |'
    local DelimForegroundColor=$(echo %{'\e[1;33m'%}) # Yellow
    local DelimBackgroundColor=

    local AfterText=']'
    local AfterForegroundColor=$(echo %{'\e[1;33m'%}) # Yellow
    local AfterBackgroundColor=

    local BranchForegroundColor=$(echo %{'\e[1;36m'%})  # Cyan
    local BranchBackgroundColor=
    local BranchAheadForegroundColor=$(echo %{'\e[1;32m'%}) # Green
    local BranchAheadBackgroundColor=
    local BranchBehindForegroundColor=$(echo %{'\e[0;31m'%}) # Red
    local BranchBehindBackgroundColor=
    local BranchBehindAndAheadForegroundColor=$(echo %{'\e[1;33m'%}) # Yellow
    local BranchBehindAndAheadBackgroundColor=

    local BeforeIndexText=''
    local BeforeIndexForegroundColor=$(echo %{'\e[1;32m'%}) # Dark green
    local BeforeIndexBackgroundColor=

    local IndexForegroundColor=$(echo %{'\e[1;32m'%}) # Dark green
    local IndexBackgroundColor=

    local WorkingForegroundColor=$(echo %{'\e[0;31m'%}) # Dark red
    local WorkingBackgroundColor=

    local StashForegroundColor=$(echo %{'\e[0;34m'%}) # Darker blue
    local StashBackgroundColor=
    local StashText=\\'*'

    local RebaseForegroundColor=$(echo %{'\e[0m'%}) # reset
    local RebaseBackgroundColor=

    local EnableFileStatus=true
    local ShowStashState=true
    local ShowStashCount=true
    local EnableStatusSymbol=true

    #local a=$(date "+%s.%N") #cheez1
    #local b=$(date "+%s.%N") #cheez2
    #echo $(($b - $a))        #cheez3

    local BranchIdenticalStatusSymbol=''
    local BranchAheadStatusSymbol=''
    local BranchBehindStatusSymbol=''
    local BranchBehindAndAheadStatusSymbol=''
    local BranchWarningStatusSymbol=''
    if $EnableStatusSymbol; then
        BranchIdenticalStatusSymbol=$' \xE2\x89\xA1' # Three horizontal lines
        BranchAheadStatusSymbol=$' \xE2\x86\x91' # Up Arrow
        BranchBehindStatusSymbol=$' \xE2\x86\x93' # Down Arrow
        BranchBehindAndAheadStatusSymbol=$' \xE2\x86\x95' # Up and Down Arrow
        BranchWarningStatusSymbol=' ?'
    fi

    # these globals are updated by __posh_git_ps1_upstream_divergence
    __POSH_BRANCH_AHEAD_BY=0
    __POSH_BRANCH_BEHIND_BY=0

    local g=$(git rev-parse --git-dir)
    if [ -z "$g" ]; then
        return # not a git directory
    fi
    local rebase=''
    local b=''
    local step=''
    local total=''
    if [ -d "$g/rebase-merge" ]; then
        b=$(cat "$g/rebase-merge/head-name" 2>/dev/null)
        step=$(cat "$g/rebase-merge/msgnum" 2>/dev/null)
        total=$(cat "$g/rebase-merge/end" 2>/dev/null)
        if [ -f "$g/rebase-merge/interactive" ]; then
            rebase='|REBASE-i'
        else
            rebase='|REBASE-m'
        fi
    else
        if [ -d "$g/rebase-apply" ]; then
            step=$(cat "$g/rebase-apply/next")
            total=$(cat "$g/rebase-apply/last")
            if [ -f "$g/rebase-apply/rebasing" ]; then
                rebase='|REBASE'
            elif [ -f "$g/rebase-apply/applying" ]; then
                rebase='|AM'
            else
                rebase='|AM/REBASE'
            fi
        elif [ -f "$g/MERGE_HEAD" ]; then
            rebase='|MERGING'
        elif [ -f "$g/CHERRY_PICK_HEAD" ]; then
            rebase='|CHERRY-PICKING'
        elif [ -f "$g/REVERT_HEAD" ]; then
            rebase='|REVERTING'
        elif [ -f "$g/BISECT_LOG" ]; then
            rebase='|BISECTING'
        fi

        b=$(git symbolic-ref HEAD 2>/dev/null) || {
            b=$(git describe --tags --exact-match HEAD 2>/dev/null) ||
            b=$(cut -c1-7 "$g/HEAD" 2>/dev/null)... ||
            b='unknown'
            b="($b)"
        }
    fi

    if [ -n "$step" ] && [ -n "$total" ]; then
        rebase="$rebase $step/$total"
    fi

    local hasStash=false
    local stashCount=0
    local isBare=''

    # TODO: 0.19 {
    if [ 'true' = "$(git rev-parse --is-inside-work-tree 2>/dev/null)" ]; then
        if $ShowStashState; then
            git rev-parse --verify refs/stash >/dev/null 2>&1 && hasStash=true
            if $ShowStashCount && $hasStash; then
                stashCount=$(git stash list | wc -l | tr -d '[:space:]')
            fi
        fi
        __posh_git_ps1_upstream_divergence
        local divergence_return_code=$?
    elif [ 'true' = "$(git rev-parse --is-inside-git-dir 2>/dev/null)" ]; then
        if [ 'true' = "$(git rev-parse --is-bare-repository 2>/dev/null)" ]; then
            isBare='BARE:'
        else
            b='GIT_DIR!'
        fi
    fi
    # }

    # show index status and working directory status
    if $EnableFileStatus; then
        local indexAdded=0
        local indexModified=0
        local indexDeleted=0
        local indexUnmerged=0
        local filesAdded=0
        local filesModified=0
        local filesDeleted=0
        local filesUnmerged=0
        echo "$(git status --porcelain 2>/dev/null)" | while read -r tag rest; do
            case "${tag:0:1}" in
                A )
                    (( indexAdded++ ))
                    ;;
                M )
                    (( indexModified++ ))
                    ;;
                R )
                    (( indexModified++ ))
                    ;;
                C )
                    (( indexModified++ ))
                    ;;
                D )
                    (( indexDeleted++ ))
                    ;;
                U )
                    (( indexUnmerged++ ))
                    ;;
            esac
            case "${tag:1:1}" in
                \? )
                    (( filesAdded++ ))
                    ;;
                A )
                    (( filesAdded++ ))
                    ;;
                M )
                    (( filesModified++ ))
                    ;;
                D )
                    (( filesDeleted++ ))
                    ;;
                U )
                    (( filesUnmerged++ ))
                    ;;
            esac
        done
    fi

    local branchstring="$isBare${b##refs/heads/}"

    # before-branch text
    local gitstring="$BeforeBackgroundColor$BeforeForegroundColor$BeforeText"

    # branch
    if [[ $__POSH_BRANCH_BEHIND_BY > 0 && $__POSH_BRANCH_AHEAD_BY > 0 ]]; then
        gitstring+="$BranchBehindAndAheadBackgroundColor$BranchBehindAndAheadForegroundColor$branchstring $__POSH_BRANCH_AHEAD_BY$BranchBehindAndAheadStatusSymbol $__POSH_BRANCH_BEHIND_BY "
    elif [[ $__POSH_BRANCH_BEHIND_BY > 0 ]]; then
        gitstring+="$BranchBehindBackgroundColor$BranchBehindForegroundColor$branchstring$BranchBehindStatusSymbol$__POSH_BRANCH_BEHIND_BY"
    elif [[ $__POSH_BRANCH_AHEAD_BY > 0 ]]; then
        gitstring+="$BranchAheadBackgroundColor$BranchAheadForegroundColor$branchstring$BranchAheadStatusSymbol$__POSH_BRANCH_AHEAD_BY"
    elif [[ $divergence_return_code -eq 0 ]]; then
        # ahead and behind are both 0, and the divergence was determined successfully
        gitstring+="$BranchBackgroundColor$BranchForegroundColor$branchstring$BranchIdenticalStatusSymbol"
    else
        # ahead and behind are both 0, but there was some problem while executing the command.
        echo "ERROR! Divergence return_code: $divergence_return_code"
        gitstring+="$BranchBackgroundColor$BranchForegroundColor$branchstring$BranchWarningStatusSymbol"
    fi

    # index status
    local indexCount="$(( $indexAdded + $indexModified + $indexDeleted + $indexUnmerged ))"
    local workingCount="$(( $filesAdded + $filesModified + $filesDeleted + $filesUnmerged ))"
    if [[ $indexCount != 0 ]]; then
        gitstring+="$IndexBackgroundColor$IndexForegroundColor +$indexAdded ~$indexModified -$indexDeleted"
    fi
    if [[ $indexUnmerged != 0 ]]; then
        gitstring+=" $IndexBackgroundColor$IndexForegroundColor!$indexUnmerged"
    fi
    if [[ $indexCount != 0 && $workingCount != 0 ]]; then
        gitstring+="$DelimBackgroundColor$DelimForegroundColor$DelimText"
    fi
    if [[ $workingCount != 0 ]]; then
        gitstring+="$WorkingBackgroundColor$WorkingForegroundColor +$filesAdded ~$filesModified -$filesDeleted"
    fi
    if [[ $filesUnmerged != 0 ]]; then
        gitstring+=" $WorkingBackgroundColor$WorkingForegroundColor!$filesUnmerged"
    fi
    gitstring+="${rebase:+$RebaseForegroundColor$RebaseBackgroundColor$rebase}"

    # after-branch text
    gitstring+="$AfterBackgroundColor$AfterForegroundColor$AfterText"

    if $hasStash; then
        gitstring+="$StashBackgroundColor$StashForegroundColor$StashText$stashCount"
    fi
    gitstring+="$DefaultBackgroundColor$DefaultForegroundColor"
    echo $gitstring
}

# Updates the global variables `__POSH_BRANCH_AHEAD_BY` and `__POSH_BRANCH_BEHIND_BY`.
__posh_git_ps1_upstream_divergence ()
{
    # Find how many commits we are ahead/behind our upstream
    __POSH_BRANCH_AHEAD_BY=0
    __POSH_BRANCH_BEHIND_BY=0
    local return_code=
    echo "$(git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null)" | IFS=$' \t\n' read -r __POSH_BRANCH_BEHIND_BY __POSH_BRANCH_AHEAD_BY
    return_code=$?
    : ${__POSH_BRANCH_AHEAD_BY:=0} 
    : ${__POSH_BRANCH_BEHIND_BY:=0} 
    return $return_code
}
