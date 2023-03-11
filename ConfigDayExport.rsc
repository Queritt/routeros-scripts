# Config Day Export
# 0.3
# 2022/10/23
:local sysName [/system identity get name];
:local sysDate [/system clock get date];
:local numMounth ( [:find "rexjanfebmaraprmayjunjulagosepoctnovdec" [:pick $sysDate 0 3] -1] / 3 );
:local sysTime [/system clock get time];
:local sysVer [/system package get system version];
# :local sysVer [/system package get routeros version]; 

:local exportFile ("$sysName-daycfg-$sysVer-" . [:pick [$sysDate] 7 11] . $numMounth . [:pick [$sysDate] 4 6] . "-" . [:pick [$sysTime] 0 2] . [:pick [$sysTime] 3 5] . ".rsc");
:foreach i in=[/file find] do={:if ([:typeof [:find [/file get $i name] "$sysname-daycfg-"]]!="nil") do={/file remove $i}};
:delay 2;

/export file=$exportFile;
/log info "Configuration file saved: $exportFile";
