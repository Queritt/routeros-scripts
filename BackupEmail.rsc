# Email backup
# 0.3
# 2022/10/23
:local mail {"123@gmail.com";"123@yandex.ru"}
:local sysName [/system identity get name];
:local sysDate [/system clock get date];
:local numMounth ( [:find "rexjanfebmaraprmayjunjulagosepoctnovdec" [:pick $sysDate 0 3] -1] / 3 );
:local sysTime [/system clock get time];
:local sysVer [/system package get system version];
# :local sysVer [/system package get routeros version]; 
:local backupFile ("$sysName-bak-$sysVer-" . [:pick [$sysDate] 7 11] . $numMounth . [:pick [$sysDate] 4 6] . "-" . [:pick [$sysTime] 0 2] . [:pick [$sysTime] 3 5] . ".backup");
/ip dns cache flush;
:delay 2;
:foreach i in=[/file find] do={:if ([:typeof [:find [/file get $i name] "$sysName-bak-"]]!="nil") do={/file remove $i}};
:delay 2;
/system backup save encryption=aes-sha256 password=PASSWORD name=$backupFile;
/log info "Configuration backup saved: $backupFile";
:delay 2;
foreach k in=$mail do={
    /tool e-mail send to=$k file=$backupFile subject=("$sysName backup (" . $sysDate . ")") body=("$sysName backup file in attachment. \nROS version: $sysVer");
    :delay 10;
};
