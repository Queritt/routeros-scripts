# 0.1
# 2022/08/13
:delay 10;
:local GATE <PROVIDER-GATE>;
:local sysname [/system identity get name];

:if [/log find message~"without proper shutdown"] do={ 
    :delay 30;
    :if ( [/ping $GATE count=5 interface=ether1] > 0 ) do={
        :if [/system scheduler find name=ConfigExport disabled=yes] do={
            /system scheduler enable ConfigExport; 
            # Export Config
            :local sysdate [/system clock get date];
            :local systime [/system clock get time];
            :local exportfile ("flash/" . "$sysname-cfg-" . [:pick [$sysdate] 4 6] . [:pick [$sysdate] 0 3] . [:pick [$sysdate] 7 11] . "-" . [:pick [$systime] 0 2] . [:pick [$systime] 3 5] . ".rsc");
            /export file=$exportfile;
            /log info "Configuration file saved: $exportfile";
        }
    } else={
        :if [/system scheduler find name=ConfigExport disabled=no] do={
            /system scheduler disable ConfigExport; 
            :foreach i in=[/file find] do={:if ([:typeof [:find [/file get $i name] "$sysname-cfg-"]]!="nil") do={/file remove $i}};
            :delay 2;
            /log warning "Config protect trigered. Config has been removed.";
        }
    }
} 
