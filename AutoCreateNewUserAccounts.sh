#!/bin/bash
#
# Orinially made by udo.klein@vgu.edu.vn

# Fail upon an error, unset variable or error in pipe
set -eu -o pipefail

: "${CONF_FILE:=${0%.sh}.conf}"

if [ -e "${CONF_FILE}" ]; then
	. ./"${CONF_FILE}"
else
	echo "Notice: Cannot found configuration file '${CONF_FILE}', using default values."
fi

emaillst="User_Emails.txt"
if [ ! -f $emaillst ]; then
	echo "Input file $emaillst not found!"
	exit 0
fi
echo
ipno=$(ifconfig "${NET_DEVICE-ens160}" | grep 'inet' | \
	grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" | \
	head -n 1 | awk '{print $1}')
group="icd"
shell="/bin/bash"
logfile="AutoCreateUser.log"
date >>$logfile
for email in $(<$emaillst); do
	echo --- >>$logfile
	username=$(echo "$email" | cut -d@ -f1)
	if [[ -z "$username" ]]; then
		echo "Empty line skipped" >>$logfile
		continue
	fi
	if [[ ${username:0:1} = "*" ]]; then
		echo "User $username skipped" >>$logfile
		continue
	fi
	if [[ ${username:0:1} == [0-9] ]]; then
		username="vgustd."$username;
	fi
	if id -u "$username" >/dev/null 2>&1; then
		echo "User $username already exists" >>$logfile
		continue
	fi
	homedir="/home/$username"
	pw=$(head /dev/urandom | tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 12)
	sudo useradd -g "$group" -s "$shell" -d "$homedir" -m "$username"
	echo "$username:$pw" | sudo chpasswd
	sudo chage -d 0 "$username"
	# make detect mountpoint for the home directory
	if grep '/home' /proc/mounts >/dev/null 2>&1; then
		home_mount="/home"
	else
		home_mount="/"
	fi
	if [ "${APPLY_QUOTA=yes}" ]; then
		sudo xfs_quota -x -c "limit ${QUOTA_LIMIT_STRING- bsoft=23g bhard=25g} $username" "$home_mount"
		sudo xfs_quota -x -c "report -bih" "$home_mount" | grep "$username" >>$logfile
	 fi
	# bit of a hack, but it should work. only add that line when APPLY_QUOTA is not empty (maybe...)
	cat >>$logfile <<EOL
User account $username:$group created.
Password: $pw
Home directory: $homedir
Shell: $shell${APPLY_QUOTA+
Quota set for $username.}
EOL
	: "${HOSTNAME=$(hostname)}"

	short_hostname="${HOSTNAME#EEIT-}"
	short_hostname="${short_hostname%-SRV}" # maybe there's a better way than this
	# Is there a better way than to source this? We only need PRETTY_NAME
	test -e /etc/os-release && . /etc/os-release

	echo "Account setup complete. Sending email to ${email}..." >>$logfile
	# TODO find a diffrent flay that allows to set the name without place_holder@vgu.edu.vn
	mail -s "user account on VGU $short_hostname server" -b "${BCC_LIST-son.nt@vgu.edu.vn}" -r "$HOSTNAME Automatic Email <place_holder@vgu.edu.vn>" "$email" >/dev/null 2>&1 <<EOF
This email is automatically generated.

A user account has been created for you on VGU's server for the $short_hostname EDA tools. The $short_hostname server is a Linux machine running ${PRETTY_NAME-AlmaLinux (I think...)}. You can use Secure Shell (ssh) to connect to the server from the internal VGU network. If you are outside VGU, you first need to connect to the VGU VPN (contact your supervisor if you haven't heard anything about this, they should be able to get you an account).

The IP address of the Cadence server is: $ipno
Your user name is: $username
Note: For VGU student email addresses, the user name is vgustd."Student_ID"; and your VGU email name (without "@vgu.edu.vn") for non-students
Your initial password is: $pw

Uppon you first initial successfull login with the above credentials, you will be asked to set a new password for the account. Please do so by following the prompt on your termial/X2Go:, but usually the steps as as follow:
	1. type out the initial password, [Enter]
	2. type your new password, [Enter]
	3. type your new password again, [Enter]

Please do not share your account and/or password with anybody else. Any VGU user who has a legitimate need to use the EDA tools will be able to get a personal user account.

As an alternative solution providing a remote desktop on your local computer display, X2Go has been installed and configured on the server. In order to use X2Go, you need to install an X2Go client program on your local computer. Although various desktop managers are available on the Synopsys server (KDE, GNOME, Xfce, MATE, Cinnamon, LXQt), it is recommended to use Xfce with X2Go. Xfce is a lightweight desktop environment which is fast and low on system resources, while still being user friendly.

If you have some knowledge of UNIX/Linux networking and the X Window system, you can set up the use of X11 GUI applications on the remote Synopsys server yourself. Plain "ssh -X" X tunnelling is generally not recommended on non-wired connections, since, unlike with X2Go, the X11 traffic won't be compressed. There are a number of X Server programs for Windows for you to direct your X11 trafic into, such as Xming or Cygwin/X. Although Xming is a good product, recent versions are not free anymore and the licensing is not clear. Cygwin/X or other, similar alternatives are therefore suggested.

Some tools run as a command in a terminal shell, others need a GUI, but most tools can be executed both in a shell or with a GUI. Details will typically be provided later. Please provide information on what level of detail you need regarding the use of a remote Linux server, configuring an X11 GUI on a remote computer, and starting the tools, if you need it.

For any questions and/or comments, you may reply to this email.
EOF
	echo "User $username created. Email sent to $email."
done
echo +++ >>$logfile
exit 0
