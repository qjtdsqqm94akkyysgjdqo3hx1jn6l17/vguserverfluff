#!/bin/sh

### Script to make checking quota easier
### Usage: check_quota.sh

## MIT License
##
## Copyright (c) 2025 18874studentvgu
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.


to_human_size(){
    # numfmt counts in bytes while APPARENTLY our file commands count in KiB by default??
    if which numfmt 1>/dev/null 2>/dev/null; then
        numfmt --to=iec-i --suffix='B' --from-unit=1024 "$1"
    else # just make it to MiB and call it a day I don't care
        echo "$(expr $1 / 1024)MiB" # 1048576 == 1024 ** 2
   fi
}

set -- $(quota -wvpu | tail -n 1 | tr -s ' ' | cut -d ' ' -f 2,3,5)

if [ -n "$*" ]; then
    Q_USED="${1%\*}"
    Q_LIMIT="$2"
    Q_GRACE="$3"

    if [ "$Q_LIMIT" -eq 0 ]; then
        echo "you have no disk quota. lucky you..."
        echo ''
    else
        Q_PERCENT="$(echo "$Q_USED*100/$Q_LIMIT"|bc)"
        if [ "$Q_PERCENT" -lt "60"  ]; then
            _f_pfx='\033[1m\033[32m'
        elif [ "$Q_PERCENT" -lt "90"  ]; then
       	    _f_pfx='\033[1m\033[33m'
            extra_message="You might wanna start looking into deleting stuff you don't need."
       	elif [ "$Q_PERCENT" -lt "100"  ]; then
            _f_pfx='\033[1m\033[31m'
       	    extra_message="You REALLY should start deleting stuff about now..."
        else
            _f_pfx='\033[1m\033[31m\033[5m'
            _date_fstring="$(printf '\033[7m%s\033[27m' "$(date -d "@$Q_GRACE" +'%^c VN time (UTC+07)')")"
            extra_message="I am no longer asking. You have a grace up to $_date_fstring. Delete. Now."
        fi

        printf "You have used $_f_pfx%s\033[0m ($_f_pfx%s%%\033[0m) of your \033[1m%s\033[0m disk quota.\n\033[2m$_f_pfx\033[25m%s\033[0m\n"\
            "$(to_human_size "$Q_USED")" "$(echo "$Q_USED*100/$Q_LIMIT"|bc)"\
            "$(to_human_size "$Q_LIMIT")" "$extra_message"
    fi
else
    echo "$0: Could not get quota information for current user." >&2
    echo ''
fi

unset to_human_size Q_USED Q_LIMIT Q_GRACE _f_pfx extra_message _date_fstring
