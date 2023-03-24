## Firewall
## 0.61
## 2023/03/24
## Minor code optimize

:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    :if ( [:len $1] != 0 ) do={ [[:parse [/system script get TG source]] Text=("/$nameID:"."%0A"."$1")]; };
}

#---Function of showing information about available commands
:local Help do={
    :local help (" Firewall option: "."%0A". \
    "  > print"."%0A". \
    "  > add [ip/address]"."%0A". \
    "  > enable/disable [comment]");
    :return $help;
}

#---Address-list function
:local AddressList do={
    :local action $1;
    :local address $2;
    :if ( $action = "print" ) do={
        :local tempString (" firewall out list: " . "%0A");
        :foreach i in=[/ip firewall address-list find] do={
            :local tempComment [/ip firewall address-list get $i comment];
            :if ( $tempComment ~"OUT" ) do={:set tempString ("$tempString" . " > " . "$tempComment" . "%0A");}
        }
        :if ([:find $tempString "OUT"] < 0) do={:set tempString " firewall out list not found."}
        :return $tempString;
    }
    :if ( $action = "add" ) do={
        :do {
            [:parse ("ip firewall address-list $action address=$address list=WEB-2 timeout=01:00:00 comment=\"Firewall-script\"")];
            :return (" Firewall: " . "\"$address\"" . " successfully " . "$action" . "ed to list \"WEB-2\".");
        } on-error={ :return "Address-list $action error: \"$address\" is wrong or already exists! Try again..."; }   
    }
    :if ( $action = "enable" || $action = "disable" ) do={
        :do {
            :foreach i in=[/ip firewall address-list find] do={
                :if ( [/ip firewall address-list get $i comment] = $address ) do={
                    :if ( $action = "enable" && [/ip firewall address-list get $i disabled] \
                        || $action = "disable" && ![/ip firewall address-list get $i disabled]) do={
                        [:parse ("ip firewall address-list $action [find comment=$address]")];
                        :return (" Firewall: " . "\"$address\"" . " successfully " . "$action" . "d.");
                    } else={ :return (" Firewall: " . "\"$address\"" . " already " . "$action" . "d!"); }   
                }
            }
            :return " Firewall $action error: \"$address\" not found! Try again..."; 
        } on-error={ :return " Firewall $action error: something went wrong! Try again..."; }  
    }
}

:if ($0 = "help" || $0 = "Help") do={ $SendMsg [$Help]; :return []; } 

:if ($0 != null) do={ 
    $SendMsg [ $AddressList $0 $1 ]; return [];
} else={ $SendMsg (" Firewall $1 error: not enough arguments. Try again..."); :return []; }
