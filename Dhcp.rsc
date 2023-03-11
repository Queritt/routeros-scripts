# DHCP client management
# ver 0.20
# modified 2022/11/12
#---Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    [[:parse [/system script get TG source]] Text=("$nameID:"."%0A"."$1")];
}
#---Function of showing information about available commands
:local Help do={
    :local help ("DHCP options: "."%0A". \
        " > print [name/all; status; netwatch; nat]"."%0A". \
        " > rename [oldname; newname/nouse]"."%0A". \
        " > set/add [nat; name; \"80/445/udp\"]"."%0A". \
        " > set [mac; name; address]"."%0A". \
        " > enable/disable/remove [netwatch/nat; name]");
    :return $help;
}
#---Function of renaming DHCP-client coment
:local Rename do={
    :local oldName $1;
    :local newName $2;
    :if ( $oldName ~"test" || $oldName ~"HM" ) do={ :put ""; } else={ :return ("DHCP rename error: editing "."\"$oldName\""." denied!"); }
    :local clientDhcp [ /ip dhcp-server lease find (comment="$oldName") ];
    if ([:len $clientDhcp] > 0) do={
        :if ($newName = "nouse") do={
           :local startLoc;
           :local tempAddress [ /ip dhcp-server lease get $clientDhcp address; ];
           :local endLoc [:len $tempAddress];
           :if ( [ :pick $tempAddress ($endLoc -1) ] ~"[0-9]" ) do={ :set startLoc ($endLoc -1) };
           :if ( [ :pick $tempAddress ($endLoc -2) ] ~"[0-9]" ) do={ :set startLoc ($endLoc -2) };
           :if ( [ :pick $tempAddress ($endLoc -3) ] ~"[0-9]" ) do={ :set startLoc ($endLoc -3) };
           :set newName ("test-".[:pick $tempAddress $startLoc $endLoc]); 
        }
        #---change comment
        /ip dhcp-server lease set $clientDhcp comment=$newName;
        #---change netwatch
        :if [/tool netwatch find comment=$oldName] do={
            /tool netwatch set [find comment="$oldName"] comment=$newName;
        }
        #---change NAT
        :if  [/ip firewall nat find comment=$oldName] do={
            /ip firewall nat set [find comment=$oldName] comment=$newName;
        }
        /log info ("$oldName".": "."\"$oldName\""." to "."\"$newName\""." successfully renamed.");
        :return ("$oldName".": "."\"$oldName\""." to "."\"$newName\""." successfully renamed.");
    } else={ :return "DHCP rename error: \"$oldName\" not found! Try again..."; }
}
#---Function of printing DHCP-client information
:local Print do={
    :local nameClient $1;
    :local tempComment;
    :local tempAddress;
    :local tempArgument;
    :local tempString "";
    :local clientDhcp;
    :if ($nameClient = "all" || $nameClient = "ALL") do={ 
        :set clientDhcp [/ip dhcp-server lease find]; 
    } else={ :set clientDhcp [ /ip dhcp-server lease find (comment ~"$nameClient") ]; }
    if ([:len $clientDhcp] > 0) do={
        :for i from=0 to=([:len $clientDhcp] - 1) do={
            :set tempComment [ /ip dhcp-server lease get [:pick $clientDhcp ($i)] comment; ];
            :set tempAddress [ /ip dhcp-server lease get [:pick $clientDhcp ($i)] address; ];
            :set tempString  ("$tempString"."name: "."\"$tempComment\"".":"."%0A"." > address: "."$tempAddress"."%0A");
            #---Status
            :if ($2 = "status" || $3 = "status" || $4 = "status") do={
                :set tempArgument [/ip dhcp-server lease get [find comment=$tempComment] status; ];
                :set tempString ("$tempString"." > status: "."$tempArgument"."%0A");
            }
            #---Netwatch
            :if ($2 = "netwatch" || $3 = "netwatch" || $4 = "netwatch") do={
                :if ( [ /tool netwatch find comment="$tempComment"; ] ) do={
                    :if ( [ /tool netwatch find comment="$tempComment" disabled=no; ] ) do={
                        :set tempString ("$tempString"." > netwatch: existed and enabled."."%0A");
                    } else={
                        :set tempString ("$tempString"." > netwatch: existed and disabled."."%0A");
                    }
                } else={
                    :set tempString ("$tempString"." > netwatch: not existed"."%0A");
                }
            }
            #---NAT
            :if ($2 = "nat" || $3 = "nat" || $4 = "nat") do={
                :if ( [ /ip firewall nat find comment="$tempComment"; ] ) do={
                    :local port [ /ip firewall nat get [find comment="$tempComment"] dst-port; ]
                    :if ( [ /ip firewall nat find comment="$tempComment" disabled=no; ] ) do={
                        :set tempString ("$tempString"." > nat: existed and enabled.; Port: "."$port"."%0A");
                    } else={
                        :set tempString ("$tempString"." > nat: existed and disabled.; Port: "."$port"."%0A");
                    }
                } else={
                        :set tempString ("$tempString"." > nat: not existed"."%0A");
                }
            }
        }
        :return $tempString;
    } else={ :return "DHCP print error: \"$nameClient\" not found! Try again..."; }
}
#---Function of Enabling Disabling Removing DHCP-client information
:local EnableDisableRemove do={
    :local action $1;
    :local target $2;
    :local nameClient $3;
    :local clientDhcp [ /ip dhcp-server lease find (comment="$nameClient") ];
    if ([:len $clientDhcp] > 0) do={
        :local clientComment [ /ip dhcp-server lease get $nameClient comment; ];
        :if ($target = "netwatch") do={
            :if [ /tool netwatch find comment="$clientComment"; ] do={
                [:parse ("tool netwatch $action [find comment=$clientComment]")];
                :return ("\"$nameClient\""." netwatch successfully "."$action"."d."); 
            } else={ :return "$target error: \"$nameClient\" not exist! Try again..."; }
        } 
        :if ($target = "nat") do={
            :if [ /ip firewall nat find comment="$clientComment"; ] do={
                [:parse ("ip firewall nat $action [find comment=$clientComment]")];
                :return ("\"$nameClient\""." nat successfully "."$action"."d."); 
            } else={ :return "$target error: \"$nameClient\" not exist! Try again..."; }
        }  
        :return "Edit error: \"$target\" not recognized! Try again..."; 
    } else={ :return "Edit error: client \"$nameClient\" not found! Try again..."; }
}
#---Function of setting NAT
:local SetAdd do={
    :local action $1;
    :local target $2;
    :local nameClient $3;
    :local port $4;
    :local protocol "tcp";
    if ( [/ip dhcp-server lease find (comment="$nameClient")] = "") do={ :return "DHCP setting error: client \"$nameClient\" not found! Try again..."; }
    #--- Nat Set
    :if ( ($target = "nat") && ([:len $port] > 0) ) do={
        :local clientAddress [ /ip dhcp-server lease get $nameClient address; ];
        :local externalAddress [ /ip address get [find interface="ether1"] address; ];
        :set externalAddress [:pick $externalAddress 0 [:find $externalAddress "/" -1]];
        #--- Replacing "/" to ","
        :local string $port;
        :local newString "";
        :if ([:find $string "/" -1] > 0) do={
            :for i from=0 to=([:len $string] -1) step=1 do={
                :local actualchar [:pick $string $i];
                :if ($actualchar = "/") do={ :set actualchar "," };
                :set newString ($newString.$actualchar);
            }  
            :set port $newString; 
        }
        #--- Spliting protocol/port 
        :if ( $port~"[a-zA-Z]" ) do={
            :local flag "";
            :local int 0;
            :while ( ([:len $flag] = 0) && ($int < [:len $port]) ) do={
                :local actualchar [:pick $port $int];
                :if ($actualchar~"[a-zA-Z]") do={ 
                    :set flag $int;
                }
                :set int ($int + 1);
            }
            :set protocol [ :pick $port $flag [:len $port] ];
            :set port [ :pick $port 0 ($flag - 1) ];
        }
        :if ( $action = "set" && [ /ip firewall nat find comment="$nameClient"; ] = 0 ) do={ 
            :return "$target set error: \"$nameClient\" not exist! Try again..."; 
        }
        :if ( $action = "add" && [ /ip firewall nat find comment="$nameClient"; ] ) do={ 
            :return "$target add error: \"$nameClient\" already exist! Try again..."; 
        }
        :do {
            :if ( $action = "set" ) do={ 
                [:parse ("ip firewall nat $action [find comment=$nameClient] dst-port=$port protocol=$protocol")];
                :return ("\"$nameClient\""." nat $port/$protocol successfully set"); 
            } 
            :if ( $action = "add" ) do={ 
                [:parse ("ip firewall nat $action action=dst-nat chain=dstnat comment=$nameClient dst-address=$externalAddress \
                    dst-port=$port in-interface=ether1 protocol=$protocol to-addresses=$clientAddress")];
                :return ("\"$nameClient\""." nat $port/$protocol successfully added"); 
            }
        } on-error={ :return "$target $action error: wrong protocol or port! Try again..."; }
    }
    :if ( $target = "mac" ) do={
        :if ( $nameClient ~"test" || $nameClient ~"HM" ) do={ :put ""; } else={ :return ("DHCP mac error: editing "."\"$nameClient\""." denied!"); }
        :if ( [:len $port] = 0 ) do={ :return ("MAC is empty. Try again..."); }
        :do {
            [:parse ("ip dhcp-server lease $action [find comment=$nameClient] mac-address=$port")];
            :return ("DHCP: " . "\"$nameClient\"" . " mac successfully changed."); 
        } on-error={ :return "DHCP $target $action error: wrong format! Try again..."; }
    }
    :return "DHCP setting error: option \"$target\" or port not recognized! Try again..."; 
}
#---MAIN---#
#---Print
:if ($0 = "print") do={
    :if ($1 != null) do={
        $SendMsg [ $Print $1 $2 $3 $4 ]; return [];
    } else={ $SendMsg ("DHCP $0 error: not enough arguments. Try again..."); :return []; } 
} 
#---Rename
:if ($0 = "rename") do={
    :if ($2 != null) do={
        $SendMsg [ $Rename $1 $2 ]; return [];
    } else={ $SendMsg ("DHCP $0 error: not enough arguments. Try again..."); :return []; } 
} 
#---Enable, disable, remove
:if ($0 = "enable" || $0 = "disable" || $0 = "remove") do={
    :if ($2 != null) do={ 
        $SendMsg [ $EnableDisableRemove $0 $1 $2 ]; return [];
    } else={ $SendMsg ("DHCP $0 error: not enough arguments. Try again..."); :return []; } 
} 
#---Set, Add
:if ($0 = "set" || $0 = "add") do={
    :if ($2 != null) do={ 
        $SendMsg [ $SetAdd $0 $1 $2 $3 ]; return [];
    } else={ $SendMsg ("DHCP $0 error: not enough arguments. Try again..."); :return []; } 
} 
#---Help
$SendMsg [$Help];
