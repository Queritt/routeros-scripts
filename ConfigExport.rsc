# Config Export
# 0.40
# 2023/01/05
:local sysName [/system identity get name];
:local sysDate [/system clock get date];
:local numMounth ( [:find "rexjanfebmaraprmayjunjulagosepoctnovdec" [:pick $sysDate 0 3] -1] / 3 );
:if ( [:len $numMounth] = 1 ) do={ :set numMounth ("0" . "$numMounth") };
:local sysTime [/system clock get time];
# ROS 6.x ::
# :local sysVer [/system package get system version];
# ROS 7.x ::
:local sysVer [/system package get routeros version]; 

:local FreeSpace do={
	/file remove [find name="tmp.rsc"];
	/export file="tmp.rsc";
	:delay 2;
	:local newFileSize [/file get [find name="tmp.rsc"] size];
	:local freeSpace [/system resource get free-hdd-space];
	/file remove [find name="tmp.rsc"];
	# Free HDD space + 100kb
	:if ( ($newFileSize + 102400) <= $freeSpace ) do={ :return true } else={ :return false };
}

:if [$FreeSpace] do={
	:local exportFile ("flash/" . "$sysName-cfg-$sysVer-" . [:pick [$sysDate] 7 11] . $numMounth . [:pick [$sysDate] 4 6] . "-" . [:pick [$sysTime] 0 2] . [:pick [$sysTime] 3 5] . ".rsc");
	:foreach i in=[/file find] do={:if ([:typeof [:find [/file get $i name] "$sysname-cfg-"]]!="nil") do={/file remove $i}}; 
	:delay 2;
	/export file=$exportFile; 
	:delay 2;
	/log info "Configuration file saved: $exportFile";
} else={ /log warning "Backup unsuccessful: not enough space."; }
