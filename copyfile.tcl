
########################


set floppy [lindex $argv 0]
set filen [lindex $argv 1]
set uc_file [string toupper $filen]

spawn su root

expect "Password: "
send "123456\r"

expect "]# "
send "mount ${floppy} /mnt\r"

expect "]# "
send "cp ${filen} /mnt/${uc_file}\r"

expect "]# "
send "umount /mnt\r"

expect "]# "
send "exit\r"


sleep 1


