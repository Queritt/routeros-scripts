# 0.1
# 2022/08/13
:local sysname [/system identity get name];
:local sysdate [/system clock get date];
:local systime [/system clock get time];
:local exportfile ("flash/" . "$sysname-cfg-" . [:pick [$sysdate] 4 6] . [:pick [$sysdate] 0 3] . [:pick [$sysdate] 7 11] . "-" . [:pick [$systime] 0 2] . [:pick [$systime] 3 5] . ".rsc");

:foreach i in=[/file find] do={:if ([:typeof [:find [/file get $i name] "$sysname-cfg-"]]!="nil") do={/file remove $i}};
:delay 2;

/export file=$exportfile;
/log info "Configuration file saved: $exportfile";
