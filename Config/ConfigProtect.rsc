# Config Protect
# 0.40
# 2022/10/25
:delay 10;
:local pingGate GATE;
:if [/log find message~"without proper shutdown"] do={ 
    :delay 30;
    :if ( [/ping $pingGate count=5 interface=ether1] > 0 ) do={
        :if [/system scheduler find name=ConfigExport disabled=yes] do={
            /system scheduler enable ConfigExport; 
            /system script run ConfigExport;
        }
    } else={
        :if [/system scheduler find name=ConfigExport disabled=no] do={
            /system scheduler disable ConfigExport; 
            :foreach i in=[/file find] do={:if ([:typeof [:find [/file get $i name] "$sysname-cfg-"]]!="nil") do={/file remove $i}};
            :delay 2;
            /log warning "Config protect trigered. Config removed.";
        }
    }
} 
