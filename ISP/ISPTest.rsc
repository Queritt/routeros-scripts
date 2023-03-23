## ISPTest
## 0.43
## 2023/03/23
## Add exception list
## Run from router: [[:parse [/system script get ISPTest source]] run all noprint];

:global Resolve do={ :do {:if ([:typeof [:tonum $1]] != "num") do={:return [:resolve $1];}; :return $1;} on-error={:return 0.0.0.1;}; }

## Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    :if ( [:len $1] != 0 ) do={ [[:parse [/system script get TG source]] Text=("/$nameID:"."%0A"."$1")]; };
}

:local Help do={
    :local help ("ISPTest option: "."%0A". \
        " > print (only wan)"."%0A". \
        " > run [interface name; all]");
    :return $help;
}

:local Print do={
    :local extInfList "WAN";
    :local pingInf ("ISPTest:" . "%0A" . " wan interfaces:" . "%0A");
    :local tmpStatus;
    :foreach n in=[/interface list member find list=$extInfList] do={
        :local tmpInf [/interface list member get $n interface];
        :if ( [:typeof [:find $tmpInf "*"]] = "nil" ) do={
            :if [/interface get $tmpInf disabled] do={:set tmpStatus " /down"} else={:set tmpStatus " /up"}
            :set pingInf ("$pingInf" . "  > $tmpInf $tmpStatus" . "%0A");
        }
    }
    :if ( [:len $pingInf] = 0) do={ :return ("ISPTest: interfaces not found!"); } else={ :return $pingInf; }
}

:local Run do={
    :global Resolve;
    :local runInf $1;
    :local printKey ($2 = "noprint");
    :local extInfList "WAN";
    :local pingInf [/interface list member find list=$extInfList];
    :local pingHost {"yandex.ru"; "google.com"; "youtube.com"; "mail.ru"};
    :local exceptionList {"ovpn-out1"};
    :local exceptionFound false;
    ## percent of good ping: ping > %%
    :local pingCnt 10;
    :local failProc 50;
    :local infOk false;
    :local res ("ISPTest: " . "%0A");
    :local wanList;
    ## One of WAN member is exist
    :if ( [:len $pingInf] = 0) do={:return ("ISPTest: WAN interfaces not found!");};
    :local tmpPingInf ({});
    :foreach n in=$pingInf do={
        :if ([:len [:find $exceptionList [/interface list member get $n interface]]] = 0) do={:set tmpPingInf ($tmpPingInf, $n)}
    }
    :set pingInf $tmpPingInf;
    :if ($runInf = "all") do={
        :local resAll;
        :local tmpInf;
        :foreach n in=$pingInf do={ 
            :set tmpInf [/interface list member get $n interface];
            :if ( [:typeof [:find $tmpInf "*"]] = "nil" ) do={
                :if ( ![/interface get [find name=$tmpInf] disabled] ) do={
                    :set infOk false;
                    :foreach k in=$pingHost do={
                        :local tmpPing 0;
                        :local tmpIp [$Resolve $k];
                        :put "";
                        :put ("$tmpInf".":");
                        :set tmpPing [/ping address=$tmpIp count=$pingCnt interface=$tmpInf];
                        :if ( (100 * $tmpPing / $pingCnt) > $failProc) do={ :set infOk true; } 
                        :put (" > ping host = "."$k");
                        :put (" > ping Ok = "."$infOk");
                        :put "";
                     }
                    :if ( $infOk ) do={ 
                        :if (!$printKey) do={ :set resAll ( "$resAll" . " > $tmpInf - OK!"."%0A"); }
                    } else={ 
                        :if ($printKey) do={
                            :set resAll ("$resAll" . " $tmpInf - FAIL!".";"); 
                        } else={ :set resAll ("$resAll" . " > $tmpInf - FAIL!"."%0A"); };                   
                    }
                }
            }
        }
        :if ( [:len $resAll] != 0 ) do={ 
            :if ($printKey) do={:log warning ("ISPTest:" . "$resAll"); return [];} else={:return ("ISPTest: " . "%0A" . "$resAll");}
        } else={ :return [] };
    }
    ## Interface name is empty
    :if ($runInf = null) do={
        :return (" ISPTest:"."%0A"."  > interface cannot be empty, try again...");
    }
    ## Interface is exisning
    :if ( [:len [/interface find name=$runInf] ] = 0 ) do={
        :return (" ISPTest:"."%0A"."  > interface \"$runInf\" not exist, try again...");
    }
    ## Interface is WAN
    :foreach n in=$pingInf do={ :set wanList ("$wanList" . [/interface list member get $n interface]); }
    :if ( [:typeof [:find $wanList $runInf] ] != "num" ) do={ :return (" ISPTest:"."%0A"."  > interface \"$runInf\" not wan, use \"print\"..."); }
    ## Interface is disabled
    :if [/interface get [find name=$runInf] disabled] do={
        :return (" ISPTest:"."%0A"."  > interface \"$runInf\" is disabled, try again...");
    }
    :foreach k in=$pingHost do={
        :local tmpPing 0;
        :local tmpIp [$Resolve $k];
        :set tmpPing [/ping address=$tmpIp count=$pingCnt interface=$runInf];
        :set res ("$res" . "$k" . ":" . "%0A" . " > " . $tmpIp . " - " . "$tmpPing" . "/$pingCnt");
        :if ( (100 * $tmpPing / $pingCnt) > $failProc) do={
            :set infOk true;
            :set res ("$res" . " - ok" . "%0A");
        } else={:set res ("$res" . " - fail" . "%0A");};
    }
    :if ( $infOk ) do={ :return ("$res"."---"."%0A"." $runInf - OK!"); } else={ :return ("$res"."---"."%0A"." $runInf - FAIL!");}
}

## Main
:if ($0 = "print") do={ $SendMsg [$Print]; return []; } 
:if ($0 = "run") do={ $SendMsg [$Run $1 $2]; return []; } 
$SendMsg [$Help];
