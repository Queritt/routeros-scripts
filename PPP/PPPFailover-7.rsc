## PPPFailover
## 0.81 / 7.x
## 2023/03/04
## RenewList fills into every server changing.
## Changing server from file
## File in flash and contains name as "providerName" value

:global Resolve do={ :do {:if ([:typeof [:tonum $1]] != "num") do={:return [:resolve $1];}; :return $1;} on-error={:return 0.0.0.1;}; }

:global Ping do={
    ## Value required: $1(address); count; [interface]
    :local res 0;
    :local val " address=$1 count=1 as-value";
    :if ([:len $interface] != 0) do={:set val ($val." interface=$interface");};
    :for i from=1 to=$count do={:if ([[:parse "/ping $val"]]->"status" = null) do={:set res ($res + 1);};};
    :return $res;
}

:global HostPing do={
    ## Value required: host; count; [interface]
    :global Ping; :global Resolve; :local res 0;
    :foreach k in=$host do={:set res ($res + [$Ping [$Resolve $k] count=$count interface=$interface]);};
    :return $res;
}

:local FileToArray do={
    :local fileName $1;
    :local serverList; 
    :local serverListLen;
    :do {
        :set serverList [/file get [/file find name~"$fileName"] contents]; 
        :set serverListLen [:len $serverList];
    } on-error={ /log warning "FileToArray: \"$fileName\" file not found or size more 4096 bytes."; }
    :local address ""; :local countryCity ""; :local country ""; :local city ""; :local lineEnd 0; :local line ""; :local lastEnd 0;
    :local array;
    :local entry;
    :do {
        :set lineEnd [:find $serverList "\n" $lastEnd];
        :set line [:pick $serverList $lastEnd $lineEnd];
        :set lastEnd ( $lineEnd +1 ); 
        :set entry [:pick $line 0 $lineEnd];
        :set address [:pick $entry 0 ( [:find $entry "-"] -1 )];
        :set countryCity [:pick $entry ( [:find $entry "-"] +2 ) ([:len $entry] -1 ) ];
        :set country [:pick $countryCity 0 [:find $countryCity ","]]; 
        :set city [:pick $countryCity ([:find $countryCity ","]+2) [:len $countryCity]];
        :set array ($array, {"$address", "$country", "$city"});
    } while ( $lastEnd < ( $serverListLen -2 ) )
    :return $array;
}

#---Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    :if ( [:len $1] != 0 ) do={ [[:parse [/system script get TG source]] Text=("/$nameID:"."%0A"."$1")]; };
}

:local Help do={
    :local help ("PPPFailover option: "."%0A". \
        " > renew [main1; main2]" . "%0A". \
        " > reset [main1; main2; all]");
    :return $help;
}

:local ChangeServer do={
    :local providerName $1;
    :local clientName $2;
    :local clientComment $3;
    :local preferList $4;
    :local oneListClient $5;
    :local renewList $6;
    :local existAddress ({});
    :global main1Renew;
    :global main2Renew;
    :global serverList;
    :local address "";
    :local country "";
    :local city "";
    :local suiteStatus false;
    :foreach i in=[/interface l2tp-client find (comment ~"$providerName")] do={
        :set existAddress ($existAddress, [/interface l2tp-client get $i connect-to]);
    }
    #--Setting prever list by name client
    :foreach preferCountry in=$preferList do={
        :for n from=0 to=([:len $serverList]-1) do={
            :set address [:pick [:pick $serverList $n] 0];
            :set country [:pick [:pick $serverList $n] 1];
            :set city    [:pick [:pick $serverList $n] 2];
            :set suiteStatus ($preferCountry = $country);
            :if ($suiteStatus) do={ :set suiteStatus ([:typeof [:find $existAddress $address]] = "nil") };
            :if ($suiteStatus) do={ :set suiteStatus ([:typeof [:find $renewList "$address"]] != "num") };
            :if ($suiteStatus) do={ :set suiteStatus ([/ping address=$address count=3] > 0) };
            :if ($suiteStatus) do={
                :local tempComment ($clientComment . "-" . $providerName . "-" . $country . ", " . $city);
                /interface l2tp-client set $clientName connect-to=$address comment=$tempComment;
                :if ($clientComment = "main1") do={ 
                    :set $main1Renew ( $main1Renew, "$address"); 
                } else={ :set $main2Renew ( $main2Renew, "$address" ); }
                :return ("PPP-OUT-$clientComment DOWN. Host changed: " . "\"$country, $city\"");
            }
        }
    }
    #--If not found prefer country (NOT for onlyOneListClient)
    :if ( [:typeof [:find $oneListClient $clientName] ] = "nil" ) do={
        :for n from=0 to=([:len $serverList]-1) do={
            :set address [:pick [:pick $serverList $n] 0];
            :set country [:pick [:pick $serverList $n] 1];
            :set city    [:pick [:pick $serverList $n] 2];
            :set suiteStatus ([:typeof [:find $existAddress $address]] = "nil");
            :if ($suiteStatus) do={ :set suiteStatus ([:typeof [:find $renewList "$address"]] != "num") };
            :if ($suiteStatus) do={ :set suiteStatus ([/ping address=$address count=3] > 0) };
            :if ($suiteStatus) do={
                :local tempComment ($clientComment . "-" . $providerName . "-" . $country . ", " . $city);
                /interface l2tp-client set $clientName connect-to=$address comment=$tempComment;
                :if ($clientComment = "main1") do={ 
                    :set $main1Renew ( $main1Renew, "$address"); 
                } else={ :set $main2Renew ( $main2Renew, "$address" ); }
                :return ("PPP-OUT-$clientComment DOWN. Prefer not found, host changed: " . "\"$country, $city\"");
            }
        }
    } else={ 
        :if ($clientComment = "main1") do={ :set $main1Renew ({}); } else={:set $main2Renew ({}); };
        :return "PPP-OUT-$clientComment DOWN. Prefer host not found!" 
    };
    :if ($clientComment = "main1") do={ :set $main1Renew ({}); } else={:set $main2Renew ({}); };
    :return "PPP-OUT-$clientComment DOWN. Working or prefer host not found!";
}
#--MAIN
#-- VERY IMPORTANT INFORMATION BELOW:
# File list name and provider comment must contain provider name!
:global pingHost {"yandex.ru"; "google.com"; "mail.ru"};
:global main1Renew;
:global main2Renew;
:global serverList;
:local action $0;
:local renewInf $1;
:local renewCheck ($action = "renew");
:local main1Inf l2tp-out1;
:local main2Inf l2tp-out2;
:local providerName "hidemy.name";
:local main1InfPreferList {"Russia"; "Latvia"; "Lithuania"; "Estonia"};
:local main2InfPreferList {"Latvia"; "Germany"; "Finland"; "Sweden"; "Netherlands"};
:local InfOneList {"l2tp-out1"};

:if ([:len $serverList] <20) do={:set serverList [$FileToArray $providerName]};

:if ( $action = "help" || $action = "Help") do={
    $SendMsg [$Help]; :return [];
}

:if ($action = "reset") do={ 
    :if ($renewInf = "all") do={:set $main1Renew ({}); :set $main2Renew ({}); :return [$SendMsg (" PPPFailover: all renew-lists reseted.")];};
    :if ($renewInf = "main1") do={:set $main1Renew ({}); :return [$SendMsg (" PPPFailover: main1 renew-list reseted.")];};
    :if ($renewInf = "main2") do={:set $main2Renew ({}); :return [$SendMsg (" PPPFailover: main2 renew-list reseted.")];};
    $SendMsg [$Help]; :return [];
}

:if ($action = "renew") do={
    :if ($renewInf = "main1") do={
        /log warning ("Renew: ".[$ChangeServer $providerName $main1Inf "main1" $main1InfPreferList $InfOneList $main1Renew]); return [];
    }
    :if ($renewInf = "main2") do={
        /log warning ("Renew: ".[$ChangeServer $providerName $main2Inf "main2" $main2InfPreferList $InfOneList $main2Renew]); return [];
    }
    $SendMsg [$Help]; :return [];
}

:if ([:len $action] !=0) do={$SendMsg [$Help]; :return [];}

## ISP Ping
:if ([$HostPing host=$pingHost count=1] = 0) do={:return []};
## Out-1 ping Step-1
:if ([$HostPing host=$pingHost count=1 interface=$main1Inf] = 0) do={
    :delay 5s;
    ## Out-1 ping Step-2
    :if ([$HostPing host=$pingHost count=1 interface=$main1Inf] = 0) do={
        /log info [$ChangeServer $providerName $main1Inf "main1" $main1InfPreferList $InfOneList $main1Renew];
    } else={:if ([:len $main1Renew] > 3) do={:set $main1Renew ({});}};
} else={:if ([:len $main1Renew] > 3) do={:set $main1Renew ({});}};
## Out-2 ping Step-1
:if ([$HostPing host=$pingHost count=1 interface=$main2Inf] = 0) do={
    :delay 5s;
    ## Out-2 ping Step-2
    :if ([$HostPing host=$pingHost count=1 interface=$main2Inf] = 0) do={
        /log info [$ChangeServer $providerName $main2Inf "main2" $main2InfPreferList $InfOneList $main2Renew];
    } else={:if ([:len $main2Renew] > 3) do={:set $main2Renew ({});}};
} else={:if ([:len $main2Renew] > 3) do={:set $main2Renew ({});}};
