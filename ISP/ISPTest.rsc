# ISPTest
# 0.31
# Add disabled status
# 2023/01/22

:global Resolve do={ :do {:if ([:typeof [:tonum $1]] != "num") do={:return [:resolve $1];}; :return $1;} on-error={:return 0.0.0.1;}; }

#---Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    [[:parse [/system script get TG source]] Text=("/$nameID:"."%0A"."$1")];
}

:local Help do={
    :local help ("ISPTest option: "."%0A". \
        " > print (only wan)"."%0A". \
        " > run [interface name]");
    :return $help;
}

:local Print do={
    :local extInfList "WAN";
    :local pingInf ("ISPTest:" . "%0A" . " wan interfaces:" . "%0A");
    :local tmpStatus;
    :foreach n in=[/interface list member find list=$extInfList] do={
        :local tmpInf [/interface list member get $n interface];
        :if [/interface get $tmpInf disabled] do={:set tmpStatus " /off"} else={:set tmpStatus " /on"}
        :set pingInf ("$pingInf" . "  > $tmpInf $tmpStatus" . "%0A");
    }
    :if ( [:len $pingInf] = 0) do={ :return ("ISPTest: interfaces not found!"); } else={ :return $pingInf; }
}

:local Run do={
    :global Resolve;
    :local runInf $1;
    :local extInfList "WAN";
    :local pingInf [/interface list member find list=$extInfList];
    :local pingHost {"yandex.ru"; "google.com"; "youtube.com"; "mail.ru"};
    # percent of good ping: ping > %%
    :local pingCnt 1;
    :local failProc 50;
    :local infOk false;
    :local res ("ISPTest: " . "%0A");
    :local wanList;
    #--Interface name is empty
    :if ($runInf = null) do={
        :return (" ISPTest:"."%0A"."  > interface cannot be empty, try again...");
    }
    #--Interface is exisning
    :if ( [:len [/interface find name=$runInf] ] = 0 ) do={
        :return (" ISPTest:"."%0A"."  > interface \"$runInf\" not exist, try again...");
    }
    #--Interface is WAN
    :foreach n in=$pingInf do={ :set wanList ("$wanList" . [/interface list member get $n interface]); }
    :if ( [:typeof [:find $wanList $runInf] ] != "num" ) do={ :return (" ISPTest:"."%0A"."  > interface \"$runInf\" not wan, use \"print\"..."); }
    #--Interface is disabled
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
##--Main
:if ($0 = "print") do={ $SendMsg [$Print]; return []; } 
:if ($0 = "run") do={ $SendMsg [$Run $1]; return []; } 
$SendMsg [$Help];
