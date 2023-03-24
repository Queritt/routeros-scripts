## Firewall
## 0.62
## 2023/03/24
## Add func of adding host to list "PPP-OUT-2"; timeout func

:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    :if ( [:len $1] != 0 ) do={ [[:parse [/system script get TG source]] Text=("/$nameID:"."%0A"."$1")]; };
}

:local Help do={
    :local help (" Firewall option: "."%0A". \
    "  > print"."%0A". \
    "  > add [ip/address; time (min)]"."%0A". \
    "  > remove [ip/address]"."%0A". \
    "  > enable/disable [comment]");
    :return $help;
}

:local PrintList do={
    :local tempString (" firewall out list: " . "%0A");
    :foreach i in=[/ip firewall address-list find] do={
        :local tempComment [/ip firewall address-list get $i comment];
        :if ( $tempComment ~"OUT" ) do={:set tempString ("$tempString" . " > " . "$tempComment" . "%0A");}
    }
    :if ([:find $tempString "OUT"] < 0) do={:set tempString " firewall out list not found."}
    :return $tempString;
}

:local AddList do={
    :local address $1;
    :local listTime $2;
    :local hostComment "Firewall-script";
    :local clientListName "PPP-OUT-2-TMP";
    :local hostListName "WEB-2";
    :local localHost {192.168.82.0/24; 192.168.85.0/24; 192.168.86.0/24; 192.168.88.0/24; 192.168.89.0/24};
    :do {
        :foreach n in=$localHost do={
            :if ($address in $n) do={
                :if ([:len $listTime] = notning || !($listTime~"[0-9]") || ($listTime < 1 || $listTime > 1440)) do={:set listTime [:totime (10*60)]} else={:set listTime [:totime ($listTime*60)]};
                [:parse ("ip firewall address-list add address=$address list=$clientListName timeout=$listTime comment=$hostComment")];
                :return (" Firewall: $address added to list \"$clientListName\" for $listTime.");
            }   
        }
        :if ([:len $listTime] = notning || !($listTime~"[0-9]") || ($listTime < 1 || $listTime > 1440)) do={:set listTime [:totime (60*60)]} else={:set listTime [:totime ($listTime*60)]};
        [:parse ("ip firewall address-list add address=$address list=$hostListName timeout=$listTime comment=$hostComment")];
        :return (" Firewall: $address added to list \"$hostListName\" for $listTime.");
    } on-error={ :return " Firewall add error: \"$address\" is wrong or already exists."; }   
}

:local EnableDisableList do={
    :local action $1;
    :local hostComment $2;
    :do {
        :foreach i in=[/ip firewall address-list find] do={
            :if ( [/ip firewall address-list get $i comment] = $hostComment ) do={
                :if ( $action = "enable" && [/ip firewall address-list get $i disabled] \
                    || $action = "disable" && ![/ip firewall address-list get $i disabled]) do={
                    [:parse ("ip firewall address-list $action [find comment=$hostComment]")];
                    :return (" Firewall: " . "\"$hostComment\"" . " $action" . "d.");
                } else={ :return (" Firewall: " . "\"$hostComment\"" . " already " . "$action" . "d!"); }   
            }
        }
        :return " Firewall $action error: \"$hostComment\" not found in list!"; 
    } on-error={:return " Firewall $action error: something went wrong!";};  
}

:local RemoveList do={
    :local address $1;
    :local hostComment "Firewall-script";
    :local tmpComment;
    :do {
        :foreach n in=[/ip firewall address-list find] do={
            :if ($address = [/ip firewall address-list get $n address] && [/ip firewall address-list get $n comment] = $hostComment) do={
                :set tmpComment [/ip firewall address-list get $n list];
                /ip firewall address-list remove $n;
                :return (" Firewall: \"$address\" removed from list \"$tmpComment\"."); 
            }
        }
        :return " Firewall remove: \"$address\" not found in list \"$hostComment\".";
    } on-error={:return " Firewall remove error: something went wrong!";};

}

:if ($0 = "help" || $0 = "Help") do={$SendMsg [$Help]; :return [];};
:if ($0 = "print") do={$SendMsg [$PrintList]; return [];};
:if ($0 = "add") do={$SendMsg [$AddList $1 $2]; return [];};
:if ($0~"enable|disable") do={$SendMsg [$EnableDisableList $0 $1]; return [];};
:if ($0 = "remove") do={$SendMsg [$RemoveList $1]; return [];};
$SendMsg [$Help];
