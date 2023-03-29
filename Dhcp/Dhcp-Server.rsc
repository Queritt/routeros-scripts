## DhcpServer
## 0.11
## 2023/03/29
:local sysDate [/system clock get date];
:local sysTime [/system clock get time];
:local serverName "server1";
# :local serverName "server2";
:local bridgeName "LAN";
# :local bridgeName "Guest";
:local numMounth ( [:find "rexjanfebmaraprmayjunjulagosepoctnovdec" [:pick $sysDate 0 3] -1] / 3 );
:if ([:len $numMounth] = 1 ) do={ :set numMounth ("0" . "$numMounth")};
:set sysDate ([:pick [$sysDate] 7 11].$numMounth.[:pick [$sysDate] 4 6]);
:set sysTime ([:pick $sysTime 0 2].[:pick $sysTime 3 5].[:pick $sysTime 6 8]);
:foreach n in=[/ip dhcp-server lease find dynamic] do={
    :if ([/ip dhcp-server lease get $n status]="bound" && [/ip dhcp-server lease get $n comment]="" && [/ip dhcp-server lease get $n server]=$serverName) do={
        :local address [/ip dhcp-server lease get $n active-address];
        :local host [/ip dhcp-server lease get $n host-name];
        /ip dhcp-server lease set $n comment=($bridgeName."-".$sysDate."-".$sysTime);
        /log warning "Dhcp $serverName lease: $address $host";
    }
}
