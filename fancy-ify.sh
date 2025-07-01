#!/bin/sh

### Make things looks fancy smancy
### Usage: drop it in /etc/profile.d

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


# if it's just x2go logging in and an X session has not launch, bypass this enitirely
if [ -z "$DISPLAY" ]; then
 [ -n "$X2GO_SESSION" ] && return 0
fi

LOGO="$(cat <<EOF
█     █▝▀▀▀▀▙▐▌    ▐▌
█     █      ▐▌    ▐▌
▜▄   ▄▚   ▀▀█▐▌    ▐▌
 ▝▜▄▛▘▜▄▄▄▄▄▛▝▙▄▄▄▄▟▘
EOF
)"

HBAR="$(cat <<EOF
───────────────────────
EOF
)"

# when connecting via x2g, tput'd implode and somehow take the x2g session with it :(
# so no `tput cols` for now (until I find a way to safely $TERM to appease it) :((
# UPDATE: for whatever reason $TERM was not transferred over to the sub shells, causing errors
if [ "LANG" != "C" ] && [ "${COLUMNS:-"$(TERM="$TERM" tput cols)"}" -gt 28 ]; then
    echo "╭$HBAR╮"
    echo "$LOGO" | while IFS='' read -r line; do
        printf '│ \033[38;5;208m%s\033[0m │\n' "$line"
    done
    printf '│ \033[1m%21s\033[0m │\n│ \033[1m%21s\033[0m │\n'\
        "Vietnamese-German" "University"
    echo "╰$HBAR╯"
else
    printf '%s\n  \033[1m\033[38;5;208m%s\033[0m\n%s\n'\
        "=======" "VGU" "======="
fi
printf '\033[2m(something broke? come yell at \033[4meda.helpdesk@vgu.edu.vn\033[24m)\033[0m\n'

printf '\nYou have connected to: \033[4m%s\033[0m\n\n' "$HOSTNAME"

random_greeting(){
    shuf -n 1 <<'EOF'
Gutten Tag, $USER!
Welcome, $USER.
$USER has logged in.
Endfie- whoops wrong greeting.
Today is $(date)... In case you wanna know, $USER.
Hello $USER.
$USER, how's that report going?
$USER! The IC!! It-it's designing!!! RUN
How do you skibidii today fellow rizzlers?
Goodluck with the circuitry $USER.
Is today Friday?
Take it easy, $USER.
oh hi
EOF
}

make_ps1_fancy(){
    # modified from https://www.cyberciti.biz/tips/howto-linux-unix-bash-shell-setup-prompt.html
    # normal
    # 🗁 (folder unicode char) might cause issues, remove if broken
    # PS1='[\[\033[1m\]\u\[\033[38;5;208m\]@\[\033[39m\]\h \[\033[2m\033[4m\]\W\[\033[0m\]]\[\033[38;5;208m\033[1m\]\$\[\033[0m\] '
    PS1='[\[\033[1m\] \u\[\033[38;5;208m\]@\[\033[39m\]\h \[\033[2m\033[4m\]\W\[\033[0m\] ]\[\033[38;5;208m\033[1m\]\$\[\033[0m\] '
}


if [ "$LANG" != "C" ]; then
    # to remove formatting, comment this line out
    make_ps1_fancy
fi

# run `check_quota` in a sub-shell
( check_quota.sh; )

# technically I can just use -e... but posix portability :(
eval echo '"«'"$(TERM="$TERM" random_greeting)"'»"'

# clean up
unset make_ps1_fancy random_greeting
