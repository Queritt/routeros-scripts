## Wlan
## 2023/03/10
## 0.20

:local SendMsg do={
    :local nameID [/system identity get name;];
    :if ([:len $1] != 0) do={ [[:parse [/system script get TG source]] Text=("/$nameID:"."%0A"."$1")]; };
}

:local Help do={
    :local help ("Wlan option: "."%0A". \
        " > print:"."%0A". \
        "     reg"."%0A". \
        "     guest [pass; limit]"."%0A". \
        "     netwatch"."%0A". \
        " > set:"."%0A". \
        "     guest pass [gen; manual]"."%0A". \
        "     guest limit [0-90]"."%0A". \
        " > enable/disable:"."%0A". \
        "     netwatch [client name]");
    :return $help;
}

:local PrintWlan do={

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

    :local action $2;

    :do {
        :if ($1 = "guest") do={
            :if ($action = "pass") do={
                :local guestPass [/interface wireless security-profiles get Guest wpa2-pre-shared-key];
                :return (" Wlan Guest pass: ". $guestPass);
            }
            :if ($action = "limit") do={
                :local guestLimit ([/interface wireless access-list get [find comment="wlan1-Guest"] ap-tx-limit] / 1000000);
                :return (" Wlan Guest limit: ".$guestLimit."M.");
            }
            :return (" Wlan Guest print option not recognized.");
        }

        :if ($1 = "reg") do={
        :local startBuf [:toarray [/interface wireless registration-table find]];
        :if ([:len $startBuf] = 0) do={:return " Wlan registered clients not found."};
        :local inf;
        :local comment;
        :local uptime; 
        :local signal;
        :local outMsg " Wlan registered:\n";
        :foreach n in=$startBuf do={
            :set inf [/interface wireless registration-table get $n interface];
            :set comment [/interface wireless registration-table get $n comment];
            :set uptime [/interface wireless registration-table get $n uptime];
            :set signal [/interface wireless registration-table get $n signal-strength];
            :set outMsg ($outMsg." > ".$inf." / ".$comment." / ".$uptime." / ".$signal."\n");       
        };
        :set outMsg [$CP1251toUTF8 $outMsg];
        :return $outMsg;
        }

        :if ($1 = "netwatch") do={
            :local startBuf [/tool netwatch find comment~"Wlan"];
            :if ([:len $startBuf] = 0) do={:return (" Wlan netwatch client not found.");};
            :local clientComment;
            :local clientStatus;
            :local outMsg " Wlan netwatch:\n";
            :foreach n in=$startBuf do={
                :set clientComment [/tool netwatch get $n comment];
                :set clientStatus [:tobool [/tool netwatch find comment="$clientComment" disabled=no]];
                :if ($clientStatus) do={:set $clientStatus "enabled"} else={:set $clientStatus "disabled"};
                :set outMsg ($outMsg." > ".$clientComment." / ".$clientStatus."\n");
            }
            :set outMsg [$CP1251toUTF8 $outMsg];
            :return $outMsg;
        }
        :return (" Wlan print action not recognized.");
    } on-error={:return (" Wlan print: something went wrong.");}
}

:local SetWlan do={
    :do {
        :if ($1 = "guest") do={
            :local action $2;
            :local option $3;
            :if ($action = "pass") do={
                :if ($option = "gen") do={
                    :local newPass [[:parse [/system script get Password source]] 8 1];
                    /interface wireless security-profiles set Guest wpa2-pre-shared-key=$newPass;
                    :return (" Wlan Guest new pass: ". $newPass);
                } else={
                    :if ([:len $option] > 7) do={
                        /interface wireless security-profiles set Guest wpa2-pre-shared-key=$option;
                        :return (" Wlan Guest new pass: ". $option);
                    } else={ :return (" Wlan pass \"$option\"" . " less than 8 characters. Try againg..."); };
                }
            }
            :if ($action = "limit") do={
                :do {
                    :if ($option = null || $option > 90) do={:set option 10M} else={ :set option ($option . "M"); };
                    :foreach i in=[/interface wireless access-list find (comment ~"Guest")] do={
                        /interface wireless access-list set $i ap-tx-limit=$option;
                    }; 
                    :return (" Wlan Guest download limit changed to " . "\"$option\".");
                } on-error={ :return (" Wlan Guest limit error: " . "\"$option\"" . " not correct! Try again..."); }
            }
            :return (" Wlan Guest set option not recognized.");
        }
        :return (" Wlan set action not recognized.");
    } on-error={:return (" Wlan set: something went wrong.");}
}

:local EnableAndDisableWlan do={
    :local action $1;
    :local option $2;
    :local clientName $3;
    :if ($option = "netwatch") do={
        :local clientId [/tool netwatch find comment~"$clientName"];
        :if ([:len $clientId] = 0) do={:return (" Wlan: netwatch client \"$clientName\" not found.");}
        :local clientComment [/tool netwatch get $clientId comment];
        :if ($action = "enable") do={
            :if ( [/tool netwatch find comment="$clientComment" disabled=yes] ) do={
                [/tool netwatch enable $clientId];
                :return (" Wlan netwatch \"$clientComment\" enabled.");
            } else={:return (" Wlan netwatch \"$clientComment\" already enabled.")};
        }
        :if ($action = "disable") do={
            :if ( [/tool netwatch find comment="$clientComment" disabled=no] ) do={
                [/tool netwatch disable $clientId];
                :return (" Wlan netwatch \"$clientComment\" disabled.");
            } else={:return (" Wlan netwatch \"$clientComment\" already disabled.")};
        }
    }
    :return (" Wlan enable or disable action not recognized.");
}

:local action $0;
:if ($action~"help|Help") do={$SendMsg [$Help]; :return [];};
:if ($action="print") do={$SendMsg [$PrintWlan $1 $2]; :return [];};
:if ($action="set") do={$SendMsg [$SetWlan $1 $2 $3]; :return [];};
:if ($action="enable" or $action="disable") do={$SendMsg [$EnableAndDisableWlan $0 $1 $2]; :return [];};
$SendMsg [$Help];
