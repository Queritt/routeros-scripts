## Arp
## 0.14
## add split message by line
## 2023/03/31

:local SendMsg do={
    :if ([:len $1] != 0) do={
        :local nameID [/system identity get name;];
        :local outMsg $1;
        :local outMsgSplit;
        :local logPart
        :local tmpChar;
        :local maxLength (4096 - [:len ("/$nameID ")] - [:len ("(message 99 of 99):"."%0A")]);
        :local foundChar;
        :if ([:len ("/$nameID:"."%0A"."$outMsg")] > 4096) do={
            :while ([:len $outMsg] > 0) do={
                :if ([:len $outMsg] > $maxLength) do={
                    :set foundChar -1;
                    :for n from=0 to=([:len $outMsg] -3) do={
                        :set tmpChar [:pick $outMsg $n ($n +3)];
                        :if ($tmpChar = "%0A" and (($n +2) < $maxLength)) do={:set foundChar $n; :set n ($n +3);};
                    }
                    :if ($foundChar > -1) do={
                        :set outMsgSplit ($outMsgSplit, [:pick $outMsg 0 ($foundChar +3)]);
                        :set $outMsg [:pick $outMsg ($foundChar +3) [:len $outMsg]];
                    } else={
                        :set outMsgSplit ($outMsgSplit, [:pick $outMsg 0 4096]);
                        :set $outMsg [:pick $outMsg 4096 [:len $outMsg]];
                    }
                } else={:set outMsgSplit ($outMsgSplit, $outMsg); :set $outMsg "";};
            }
        } else={:set outMsgSplit {$outMsg}};
        :set logPart [:len $outMsgSplit];
        :for n from=0 to=([:len $outMsgSplit] -1) do={
            [[:parse [/system script get TG source]] \
            Text=("/$nameID "."(message ".($n+1)." of $logPart):"."%0A".[:pick $outMsgSplit $n])];
        }
    }
}

:local Help do={
    :local help (" Arp option: "."%0A". \
    "  > print [all, dynamic, static,"."%0A". \
    "   ip, mac, interface]"."%0A". \
    "  > remove [dynamic, ip, mac]");
    :return $help;
}

# Function of converting CP1251 to UTF8
# https://forummikrotik.ru/viewtopic.php?p=81457#p81457
:local CP1251toUTF8 do={
    :local cp1251 [:toarray {
        "\20";"\01";"\02";"\03";"\04";"\05";"\06";"\07";"\08";"\09";"\0A";"\0B";"\0C";"\0D";"\0E";"\0F";\
        "\10";"\11";"\12";"\13";"\14";"\15";"\16";"\17";"\18";"\19";"\1A";"\1B";"\1C";"\1D";"\1E";"\1F";\
        "\21";"\22";"\23";"\24";"\25";"\26";"\27";"\28";"\29";"\2A";"\2B";"\2C";"\2D";"\2E";"\2F";"\3A";\
        "\3B";"\3C";"\3D";"\3E";"\3F";"\40";"\5B";"\5C";"\5D";"\5E";"\5F";"\60";"\7B";"\7C";"\7D";"\7E";\
        "\C0";"\C1";"\C2";"\C3";"\C4";"\C5";"\C6";"\C7";"\C8";"\C9";"\CA";"\CB";"\CC";"\CD";"\CE";"\CF";\
        "\D0";"\D1";"\D2";"\D3";"\D4";"\D5";"\D6";"\D7";"\D8";"\D9";"\DA";"\DB";"\DC";"\DD";"\DE";"\DF";\
        "\E0";"\E1";"\E2";"\E3";"\E4";"\E5";"\E6";"\E7";"\E8";"\E9";"\EA";"\EB";"\EC";"\ED";"\EE";"\EF";\
        "\F0";"\F1";"\F2";"\F3";"\F4";"\F5";"\F6";"\F7";"\F8";"\F9";"\FA";"\FB";"\FC";"\FD";"\FE";"\FF";\
        "\A8";"\B8";"\B9"}];
    :local utf8 [:toarray {
        "0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"000A";"0020";"0020";"000D";"0020";"0020";\
        "0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";\
        "0021";"0022";"0023";"0024";"0025";"0026";"0027";"0028";"0029";"002A";"002B";"002C";"002D";"002E";"002F";"003A";\
        "003B";"003C";"003D";"003E";"003F";"0040";"005B";"005C";"005D";"005E";"005F";"0060";"007B";"007C";"007D";"007E";\
        "D090";"D091";"D092";"D093";"D094";"D095";"D096";"D097";"D098";"D099";"D09A";"D09B";"D09C";"D09D";"D09E";"D09F";\
        "D0A0";"D0A1";"D0A2";"D0A3";"D0A4";"D0A5";"D0A6";"D0A7";"D0A8";"D0A9";"D0AA";"D0AB";"D0AC";"D0AD";"D0AE";"D0AF";\
        "D0B0";"D0B1";"D0B2";"D0B3";"D0B4";"D0B5";"D0B6";"D0B7";"D0B8";"D0B9";"D0BA";"D0BB";"D0BC";"D0BD";"D0BE";"D0BF";\
        "D180";"D181";"D182";"D183";"D184";"D185";"D186";"D187";"D188";"D189";"D18A";"D18B";"D18C";"D18D";"D18E";"D18F";\
        "D001";"D191";"2116"}];
    :local convStr ""; 
    :local code "";
    :for i from=0 to=([:len $1]-1) do={
        :local symb [:pick $1 $i ($i+1)]; 
        :local idx [:find $cp1251 $symb];
        :local key ($utf8->$idx);
        :if ([:len $key]!=0) do={
            :set $code ("%$[:pick ($key) 0 2]%$[:pick ($key) 2 4]");
            :if ([pick $code 0 3]="%00") do={:set $code ([:pick $code 3 6])};
        } else={:set code ($symb)}; 
        :set $convStr ($convStr.$code);
    }
    :return ($convStr);
}

:local PrintArp do={
    :local findAddress $1;
    :local startBuf [/ip arp find];
    :local arpAddress;
    :local arpMac; 
    :local arpInf;
    :local arpComment; 
    :local arpDynamic; 
    :local outMsg;
    :foreach n in=$startBuf do={
        :set arpAddress [/ip arp get $n address];
        :set arpMac     [/ip arp get $n mac-address];
        :set arpInf     [/ip arp get $n interface];
        :set arpComment [/ip arp get $n comment];
        :set arpDynamic [/ip arp get $n dynamic];
        :if ($findAddress="all") do={
            :set outMsg ("$outMsg > $arpInf: $arpAddress $arpMac $arpComment \n");
        }
        :if (([:len $findAddress] >= 3) and ([:find ("$arpAddress $arpMac $arpInf $arpComment") $findAddress] > -1)) do={
            :set outMsg ("$outMsg > $arpInf: $arpAddress $arpMac $arpComment \n");
        }
        :if (($findAddress = "dynamic" and $arpDynamic) or ($findAddress = "static" and (!$arpDynamic))) do={
            :set outMsg ("$outMsg > $arpInf: $arpAddress $arpMac $arpComment \n"); 
        }
    };
    :if ([:len $outMsg] > 0) do={
        :return (" Arp list:"."\n"."$outMsg");
    } else={:return (" Arp print error: \"$findAddress\" empty or not found.");};
}

:local RemoveArp do={
    :local findAddress $1;
    :local startBuf [/ip arp find];
    :local arpAddress;
    :local arpMac; 
    :local arpInf;
    :local arpDynamic; 
    :local arpDynamicRemove; 
    :foreach n in=$startBuf do={
        :set arpAddress [/ip arp get $n address];
        :set arpMac     [/ip arp get $n mac-address];
        :set arpInf     [/ip arp get $n interface];
        :set arpDynamic [/ip arp get $n dynamic];
        :if (($findAddress = $arpAddress or $findAddress = $arpMac) and $arpDynamic) do={
            /ip arp remove $n;
            :return (" Arp: \"$arpAddress $arpMac $arpInf\" removed.")
        }
        :if ($findAddress = "dynamic" and $arpDynamic) do={
            :set arpDynamicRemove ("$arpDynamicRemove > $arpAddress $arpMac $arpInf \n");
            /ip arp remove $n;
        }
    }
    :if ([:len $arpDynamicRemove] > 0) do={
        :return (" Arp dynamic removed: \n $arpDynamicRemove");
    }
    :return (" Arp remove error: \"$findAddress\" empty or not found or has a comment.")
}

:if ($0 = "help" || $0 = "Help") do={$SendMsg [$Help]; :return [];};
:if ($0 = "print") do={$SendMsg [$CP1251toUTF8 [$PrintArp $1]]; return [];};
:if ($0 = "remove") do={$SendMsg [$CP1251toUTF8 [$RemoveArp $1]]; return [];};
$SendMsg [$Help];
