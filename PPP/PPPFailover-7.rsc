# PPPFailover
# 0.61 / 7.x
# Add global value for ping host
# 2023/01/20
#--Changing server

:global Resolve do={ :do {:if ([:typeof [:tonum $1]] != "num") do={:return [:resolve $1];}; :return $1;} on-error={:return 0.0.0.1;}; }

:global Ping do={
    :local pingAddress $1;
    :local pingCount $count;
    :local pingInf $interface;
    :local res 0;
    :for i from=1 to=$pingCount step=1 do={
        :if ( [:len $pingInf] = 0) do={ 
            :if ( [/ping address=$pingAddress count=1 as-value]->"status"=null ) do={:set res ($res + 1);}  
        } else={
            :if ( [/ping address=$pingAddress count=1 interface=$pingInf as-value]->"status"=null ) do={:set res ($res + 1);}   
        }
    }
    :return $res;
}

:local ChangeServer do={
    :local providerName $1;
    :local clientName $2;
    :local clientComment $3;
    :local clientGateComment $4;
    :local preferList $5;
    :local oneListClient $6;
    :local serverList [/file get [/file find name~"$providerName"] contents];
    :local serverListLen [ :len $serverList ];
    :local address "";
    :local countryCity "";
    :local country "";
    :local lineEnd 0;
    :local line "";
    :local lastEnd 0;
    :local existAddress ({});
    :foreach i in=[/interface l2tp-client find (comment ~"$providerName")] do={
        :set existAddress ($existAddress, [/interface l2tp-client get $i connect-to]);
    }
    #--Setting prever list by name client
    :foreach preferCountry in=$preferList do={
        :do {
            :set lineEnd [:find $serverList "\n" $lastEnd ];
            :set line [:pick $serverList $lastEnd $lineEnd ];
            :set lastEnd ( $lineEnd +1 ); 
            :local entry [:pick $line 0 $lineEnd ];
            :set address [:pick $entry 0 ( [:find $entry "-"] -1 )];
            :set countryCity [:pick $entry ( [:find $entry "-"] +2 ) ([:len $entry] -1 ) ];
            :set country [:pick $countryCity 0 [:find $countryCity ","]]; 
            :if ( $preferCountry = $country ) do={
                :if ( [:typeof [:find $existAddress $address]] = "nil" ) do={
                    :if ( [/ping address=$address count=3] > 0 ) do={
                        :local tempComment ($clientGateComment . "-" . $providerName . "-" . $countryCity);
                        /interface l2tp-client set $clientName connect-to=$address comment=$tempComment;
                        :return "$clientComment DOWN. Host successfully changed to \"$countryCity\"";
                    }
                }
            }
        } while ( $lastEnd < ( $serverListLen -2 ) )
    }
    #--If not found prefer country (NOT for onlyOneListClient)
    :if ( [:typeof [:find $oneListClient $clientName] ] = "nil" ) do={
        :set lastEnd 0;
        :do {
            :set lineEnd [:find $serverList "\n" $lastEnd ];
            :set line [:pick $serverList $lastEnd $lineEnd ];
            :set lastEnd ( $lineEnd +1 ); 
            :local entry [:pick $line 0 $lineEnd ];
            :set address [:pick $entry 0 ( [:find $entry "-"] -1 )];
            :set countryCity [:pick $entry ( [:find $entry "-"] +2 ) ([:len $entry] -1 ) ];
            :set country [:pick $countryCity 0 [:find $countryCity ","]]; 
            :if ( [:typeof [:find $existAddress $address]] = "nil" ) do={
                :if ( [/ping address=$address count=3] > 0) do={
                    :local tempComment ($clientGateComment . "-" . $providerName . "-" . $countryCity);
                    /interface l2tp-client set $clientName connect-to=$address comment=$tempComment;
                    :return "$clientComment DOWN. Prefer not found, host changed to \"$countryCity\".";
                }
            }
        } while ( $lastEnd < ( $serverListLen -2 ) )
    } else={ :return "$clientComment DOWN. Prefer host not found!" }
    :return "$clientComment DOWN. Working or prefer host not found!";
}
#--MAIN
#-- VERY IMPORTANT INFORMATION BELOW:
# File list name and provider comment must contain provider name!
:local main1Inf l2tp-out1;
:local main2Inf l2tp-out2;
:local providerName "hidemy.name";
:local main1InfPreferList {"Russia"; "Latvia"};
:local main2InfPreferList {"Latvia"; "Germany"; "Finland"; "Sweden"; "Netherlands"};
:local InfOneList {"l2tp-out1"};
:local main1InfPing 0;
:local main2InfPing 0;
#--Provider link
:global pingHost {"yandex.ru"; "google.com"; "mail.ru"};
:local ispPing 0;
:foreach host in=$pingHost do={ :local res [$Ping [$Resolve $host] count=1]; :set ispPing ($ispPing + $res); };
:if ($ispPing = 0) do={ :return [] };
#--Client link
foreach host in=$pingHost do={
    :local res [$Ping [$Resolve $host] count=1 interface=$main1Inf];
    :set main1InfPing ($main1InfPing + $res);
    :local res [$Ping [$Resolve $host] count=1 interface=$main2Inf];
    :set main2InfPing ($main2InfPing + $res);
}
:if ($main1InfPing = 0) do={
    /log warning [$ChangeServer $providerName $main1Inf "PPP-OUT-1" "Main1" $main1InfPreferList $InfOneList];
}
:if ($main2InfPing = 0) do={
    /log warning [$ChangeServer $providerName $main2Inf "PPP-OUT-2" "Main2" $main2InfPreferList $InfOneList];
}
