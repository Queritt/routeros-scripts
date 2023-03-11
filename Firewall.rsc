# Firewall
# ver 0.4
# modified 2022/09/22
#---Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    [[:parse [/system script get TG source]] Text=("$nameID:"."%0A"."$1")];
}
#---Function of showing information about available commands
:local Help do={
    :local help ("Firewall options: "."%0A". \
    " > list print"."%0A". \
    " > list add [ip/address]"."%0A". \
    " > list enable/disable [comment]");
    :return $help;
}
#---Address-list function
:local AddressList do={
    :local action $1;
    :local address $2;
    :if ( $action = "print" ) do={
    	:local tempString ("firewall out list: " . "%0A");
    	:foreach i in=[/ip firewall address-list find] do={
    		:local tempComment [/ip firewall address-list get $i comment];
			:if ( $tempComment ~"OUT" ) do={
				:set tempString ("$tempString" . " > " . "$tempComment" . "%0A");
			}
		}
		:return $tempString;
    }
    :if ( $action = "add" ) do={
        :do {
            [:parse ("ip firewall address-list $action address=$address list=WEB-2 timeout=01:00:00 comment=\"Firewall-script\"")];
            :return ("Firewall: " . "\"$address\"" . " successfully " . "$action" . "ed to list \"WEB-2\".");
        } on-error={ :return "Address-list $action error: \"$address\" is wrong or already exists! Try again..."; }   
    }
    :if ( $action = "enable" || $action = "disable" ) do={
        :do {
            [:parse ("ip firewall address-list $action [find comment=$address]")];
            :return ("Address-list: " . "\"$address\"" . " successfully " . "$action" . "d.");
        } on-error={ :return "Address-list $action error: \"$address\" is wrong! Try again..."; }  
    }
}
#---MAIN
#---List
:if ($0 = "list") do={
    :if ($1 != null) do={ 
        $SendMsg [ $AddressList $1 $2 ]; return [];
    } else={ $SendMsg ("Firewall $0 error: not enough arguments. Try again..."); :return []; } 
} 
#---Help
$SendMsg [$Help];
