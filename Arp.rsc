## Arp
## 0.10
## 2023/03/29

:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    :if ( [:len $1] != 0 ) do={ [[:parse [/system script get TG source]] Text=("/$nameID:"."%0A"."$1")]; };
}

:local Help do={
    :local help (" Arp option: "."%0A". \
    "  > print [all, ip, mac]"."%0A". \
    "  > remove [ip, mac]");
    :return $help;
}

:local PrintArp do={
    :local findAddress $1;
    :local startBuf [/ip arp find];
    :local arpAddress;
    :local arpMac; 
    :local arpInf;
    :local arpComment; 
    :local outMsg;
    :foreach n in=$startBuf do={
        :set arpAddress [/ip arp get $n address];
        :set arpMac     [/ip arp get $n mac-address];
        :set arpInf     [/ip arp get $n interface];
        :set arpComment [/ip arp get $n comment];
        :if (([:len $findAddress] >= 3) and ([:find ("$arpAddress $arpMac $arpInf $arpComment") $findAddress] > -1)) do={
            :set outMsg ("$outMsg"." > $arpInf".": $arpAddress "."$arpMac "."$arpComment"."%0A");
        }
        :if ($findAddress="all") do={
            :set outMsg ("$outMsg"." > $arpInf".": $arpAddress "."$arpMac "."$arpComment"."%0A");
        }
    };
    :if ([:len $outMsg] > 0) do={
        :return (" Arp list:"."%0A"."$outMsg");
    } else={:return (" Arp print error: \"$findAddress\" empty or not found.");};
}

:local RemoveArp do={
    :local findAddress $1;
    :local startBuf [/ip arp find];
    :local arpAddress;
    :local arpMac; 
    :local arpInf;
    :local arpComment;
    :foreach n in=$startBuf do={
        :set arpAddress [/ip arp get $n address];
        :set arpMac [/ip arp get $n mac-address];
        :set arpInf [/ip arp get $n interface];
        :set arpComment [/ip arp get $n comment];
        :if (($findAddress = $arpAddress || $findAddress = $arpMac) and ([:len $arpComment]) = 0) do={
            /ip arp remove $n;
            :return (" Arp: \"$findAddress $arpMac $arpInf\" removed.")
        }
    }
    :return (" Arp remove error: \"$findAddress\" empty or not found or has a comment.")
}

:if ($0 = "help" || $0 = "Help") do={$SendMsg [$Help]; :return [];};
:if ($0 = "print") do={$SendMsg [$PrintArp $1]; return [];};
:if ($0 = "remove") do={$SendMsg [$RemoveArp $1]; return [];};
$SendMsg [$Help];
