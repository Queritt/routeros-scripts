# PPP Failover by list
# 0.3
# 2022/09/20
#--Changing server
:local ChangeServer do={
    :local providerName $1;
    :local clientName $2;
    :local clientComment $3;
    :local clientGateComment $4;
    :local preferList $5;
    :local notPreferList $6;
    :local oneListClient $7;
    :local pingLimit $8
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
            :if ( [:typeof [:find $notPreferList $country] ] = "nil" && $preferCountry = $country ) do={
                :if ( [:typeof [:find $existAddress $address]] = "nil" ) do={
                    :local avgRtt;
                    :local pin;
                    :local pout;
                    /tool flood-ping address=$address count=3 do={
                        :if ($sent = 3) do={
                            :set avgRtt $"avg-rtt";
                            :set pout $sent;
                            :set pin $received;
                        }
                    }
                    :if ( $pin > 0 && $avgRtt <= $pingLimit) do={
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
            :if ( [:typeof [:find $notPreferList $country] ] = "nil" && [:typeof [:find $existAddress $address]] = "nil" ) do={
                :local avgRtt;
                :local pin;
                :local pout;
                /tool flood-ping address=$address count=3 do={
                    :if ($sent = 3) do={
                        :set avgRtt $"avg-rtt";
                        :set pout $sent;
                        :set pin $received;
                    }
                }
                :if ( $pin > 0 && $avgRtt <= $pingLimit) do={
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
:local notPreferList {""};
:local InfOneList {"l2tp-out1"};
:local pingThreshold 60;
:local main1InfPing 0;
:local main2InfPing 0;
#--Provider link
# --yandex.ru, Cloudflare, GoogleDNS, mail.ru
:local pingHost {87.250.250.242; 1.1.1.1; 8.8.8.8; 94.100.180.200};
:local ispPing 0;
:foreach host in=$pingHost do={ :local res [/ping $host count=1]; :set ispPing ($ispPing + $res); };
:if ($ispPing < 3) do={ :return [] };
#--Client link
foreach host in=$pingHost do={
    :local res [/ping $host count=2 interface=$main1Inf];
    :set main1InfPing ($main1InfPing + $res);
    :local res [/ping $host count=2 interface=$main2Inf];
    :set main2InfPing ($main2InfPing  + $res);
}
:if ($main1InfPing < 5) do={
    /log warning [$ChangeServer $providerName $main1Inf "PPP-OUT-1" "Main1" $main1InfPreferList $notPreferList $InfOneList $pingThreshold];
}
:if ($main2InfPing < 5) do={
    /log warning [$ChangeServer $providerName $main2Inf "PPP-OUT-2" "Main2" $main2InfPreferList $notPreferList $InfOneList $pingThreshold];
}
