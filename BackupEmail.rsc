# 0.1
# 2022/09/05
:local Mails {"123@gmail.com";"123@yandex.ru"}
:local sysname [/system identity get name];
:local sysver [/system package get system version];
:local sysdate [/system clock get date];
:local systime [/system clock get time];
:local backupfile ("$sysname-bak-$sysver-" . [:pick [$sysdate] 4 6] . [:pick [$sysdate] 0 3] . [:pick [$sysdate] 7 11] . "-" . [:pick [$systime] 0 2] . [:pick [$systime] 3 5] . ".backup");

# Flushing DNS and deleting last backup
/ip dns cache flush;
:delay 2;
:foreach i in=[/file find] do={:if ([:typeof [:find [/file get $i name] "$sysname-bak-"]]!="nil") do={/file remove $i}};
:delay 2;

# Making and sending backup
/system backup save encryption=aes-sha256 password=PASS name=$backupfile;
/log info "Configuration backup saved: $backupfile";
:delay 2;
foreach K in=$Mails do={
    /tool e-mail send to=$K file=$backupfile subject=("$sysname backup (" . $sysdate . ")") body=("$sysname backup file in attachment. \nROS version: $sysver");
    :delay 10;
};
