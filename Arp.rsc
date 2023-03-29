## Arp
## 0.10
## 2023/03/28

:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    :if ( [:len $1] != 0 ) do={ [[:parse [/system script get TG source]] Text=("/$nameID:"."%0A"."$1")]; };
}

:local Help do={
    :local help (" Arp option: "."%0A". \
    "  > print"."%0A". \
    "  > remove [ip]");
    :return $help;
}

:local PrintArp do={
    :local startBuf [/ip arp find];
    :local arpAddress;
    :local arpMac; 
    :local arpInf;
    :local arpComment; 
    :local outMsg (" Arp list:"."%0A")
    :foreach n in=$startBuf do={
        :set arpAddress [/ip arp get $n address];
        :set arpMac [/ip arp get $n mac-address];
        :set arpInf [/ip arp get $n interface];
        :set arpComment [/ip arp get $n comment];
        :set outMsg ("$outMsg"." > $arpInf".": $arpAddress "."$arpMac "."$arpComment"."%0A")
    };
  :return $outMsg;
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
        :if ($findAddress = $arpAddress and ([:len $arpComment]) = 0) do={
            /ip arp remove $n;
            :return (" Arp: \"$findAddress $arpMac $arpInf\" removed.")
        }
    }
    :return (" Arp: \"$findAddress\" not found or empty or has a comment.")
}

:if ($0 = "help" || $0 = "Help") do={$SendMsg [$Help]; :return [];};
:if ($0 = "print") do={$SendMsg [$PrintArp]; return [];};
:if ($0 = "remove") do={$SendMsg [$RemoveArp $1]; return [];};
$SendMsg [$Help];
