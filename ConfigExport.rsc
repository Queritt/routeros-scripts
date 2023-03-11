# Config Export
# 0.2
# 2022/10/20
:local sysname [/system identity get name];
:local sysdate [/system clock get date];
:local systime [/system clock get time];
#-- IMPORTANT! For RoS 6.xx
:local sysver [/system package get system version];
#-- IMPORTANT! For RoS 7.xx
# :local sysver [/system package get routeros version]; 

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
	:local exportfile ("flash/" . "$sysname-cfg-$sysver-" . [:pick [$sysdate] 4 6] . [:pick [$sysdate] 0 3] . [:pick [$sysdate] 7 11] . "-" . [:pick [$systime] 0 2] . [:pick [$systime] 3 5] . ".rsc");
	:foreach i in=[/file find] do={:if ([:typeof [:find [/file get $i name] "$sysname-cfg-"]]!="nil") do={/file remove $i}};
	:delay 2;
	/export file=$exportfile;
	:delay 2;
	/log info "Configuration file saved: $exportfile";
} else={ /log warning "Backup unsuccessful: not enough space."; }
