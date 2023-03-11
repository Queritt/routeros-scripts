# Email backup
# 0.40
# 2023/01/05
:local mail {"MAIL_1";"MAIL_2"}
:local sysName [/system identity get name];
:local sysDate [/system clock get date];
:local numMounth ( [:find "rexjanfebmaraprmayjunjulagosepoctnovdec" [:pick $sysDate 0 3] -1] / 3 );
:if ( [:len $numMounth] = 1 ) do={ :set numMounth ("0" . "$numMounth") };
:local sysTime [/system clock get time];
# ROS 6.x ::
# :local sysVer [/system package get system version];
# ROS 7.x ::
:local sysVer [/system package get routeros version]; 
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
