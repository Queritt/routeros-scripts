## PPPAutoPort
## Open port where client logged more than <days>
## 0.10
## 2023/03/18
:local EpochTime do={
    :local ds $1;
    :local ts $2;
    :if ([:len $1]>19) do={:set ds "$[:pick $1 0 11]"; :set ts [:pick $1 12 20]};
    :if ([:len $1]>8 && [:len $1]<20) do={:set ds "$[:pick $1 0 6]/$[:pick $ds 7 11]"; :set ts [:pick $1 7 15]};
    :local yesterday false;
    :if ([:len $1]=8) do={
        :if ([:totime $1]>ts) do={:set yesterday (true)};
        :set ts $1;
    }
    :local months;
    :if ((([:pick $ds 9 11]-1)/4)!=(([:pick $ds 9 11])/4)) do={
        :set months {"an"=0;"eb"=31;"ar"=60;"pr"=91;"ay"=121;"un"=152;"ul"=182;"ug"=213;"ep"=244;"ct"=274;"ov"=305;"ec"=335};
    } else={
        :set months {"an"=0;"eb"=31;"ar"=59;"pr"=90;"ay"=120;"un"=151;"ul"=181;"ug"=212;"ep"=243;"ct"=273;"ov"=304;"ec"=334};
    }
    :set ds (([:pick $ds 9 11]*365)+(([:pick $ds 9 11]-1)/4)+($months->[:pick $ds 1 3])+[:pick $ds 4 6]);
    :set ts (([:pick $ts 0 2]*3600)+([:pick $ts 3 5]*60)+[:pick $ts 6 8]);
    :if (yesterday) do={:set ds ($ds-1)};
    :return ($ds*86400+$ts+946684800-[/system clock get gmt-offset]);
}  

:local clientName "Guest1";
:local filterRule "allow pptp from anywhere";
:local activityPeriod 30;
:if ([:len [/ppp secret find comment="$clientName"]] = 0) do={/log warning " PPPAutoPort: client \"$clientName\" not found."; :return []};
:if ([:len [/ip firewall filter find comment="$filterRule"]] = 0) do={
    /log warning " PPPAutoPort: filter rule \"$clientName\" not found."; :return []}; 
:local curDate [/system clock get date];
:local curTime [/system clock get time];
:local clientDateTime [/ppp secret get [find comment="$clientName"] last-logged-out];
:local clientDate [:pick $clientDateTime 0 11];
:local clientTime [:pick $clientDateTime 12 20];
:local curEpochTime [$EpochTime $curDate $curTime];
:local clientEpochTime [$EpochTime $clientDate $clientTime];
:local difActive (($curEpochTime - $clientEpochTime) / 3600 / 24);

:if ($difActive > $activityPeriod or $difActive < 0) do={
    :if [/ip firewall filter find comment="$filterRule" disabled=yes] do={
        [/ip firewall filter enable [find comment="$filterRule"]];
        /log warning " PPPAutoPort: client \"$clientName\" not connected in $activityPeriod days, filter rule enabled.";
    }    
} else={
    :if [/ip firewall filter find comment="$filterRule" disabled=no] do={
        [/ip firewall filter disable [find comment="$filterRule"]];
        :local lastClientIp [/ppp secret get [find comment="$clientName"] last-caller-id];
        /log warning " PPPAutoPort: client \"$clientName\" from $lastClientIp connected in $activityPeriod days, filter rule disabled.";
    }  
}
