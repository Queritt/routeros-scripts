# PPP client management
# ver 0.24
# modified 2022/08/24

#---Function of showing information about available commands
:local Help do={
    :local help ("PPP options: "."%0A". \
        " > print [name/all; time; pass; call; netwatch; nat]"."%0A". \
        " > rename [oldname; newname/nouse]"."%0A". \
        " > set/add [nat; name; \"80/445/udp\"]"."%0A". \
        " > set [pass; name; 8-24 characters]"."%0A". \
        " > enable/disable/remove [netwatch/nat; name]");
    [[:parse [/system script get TG source]] Text=$help];
}

#---Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    [[:parse [/system script get TG source]] Text=("$nameID:"."%0A"."$1")];
}

#---Function of renaming PPP-client coment
:local Rename do={
    :local notAccessList {"PDA"; "PPP-OUT-2"; "WM"; "RDP"; "Reserved"; "OVPN"; "SSTP"}
    :local oldName $1;
    :local newName $2;
    :local clientPPP [ /ppp secret find (comment="$oldName") ];
    if ([:len $clientPPP] > 0) do={
        :foreach n in=$notAccessList do={ 
            :if ($n = $oldName) do={
                :return ("PPP rename error: editing "."\"$oldName\""." denied!");
            } 
        }
        :if ($newName = "nouse") do={
            :set newName [/ppp secret get $clientPPP name]; 
        }
        #---change secret
        /ppp secret set $clientPPP comment=$newName;
        #---change interface
        /interface set [find comment=$oldName] comment=$newName;
        #---change netwatch
        :if [/tool netwatch find comment=$oldName] do={
            /tool netwatch set [find comment="$oldName"] comment=$newName;
        }
        #---change NAT
        :if  [/ip firewall nat find comment=$oldName] do={
            /ip firewall nat set [find comment=$oldName] comment=$newName;
        }
        :local clientName [/ppp secret get [find comment="$newName"] name];
        /log info ("$clientName".": "."\"$oldName\""." to "."\"$newName\""." successfully renamed.");
        :return ("$clientName".": "."\"$oldName\""." to "."\"$newName\""." successfully renamed.");
    } else={ :return "PPP print error: \"$oldName\" not found! Try again..."; }
}

#---Function of printing PPP-client information
:local Print do={
    :local notAccessList {"PDA"; "PPP-OUT-2"; "WM"; "RDP"; "Reserved"; "OVPN"; "SSTP"};
    :local nameClient $1;
    :local tempName;
    :local tempComment;
    :local tempAddress;
    :local tempArgument;
    :local tempString "";
    :local clientPPP;
    :if ($nameClient = "all" || $nameClient = "ALL") do={ 
        :set clientPPP [/ppp secret find]; 
    } else={ :set clientPPP [ /ppp secret find (comment ~"$nameClient") ]; }

    if ([:len $clientPPP] > 0) do={
        :for i from=0 to=([:len $clientPPP] - 1) do={
            :set tempName [ /ppp secret get [:pick $clientPPP ($i)] name; ];
            :set tempComment [ /ppp secret get [:pick $clientPPP ($i)] comment; ];
            :set tempAddress [ /ppp secret get [:pick $clientPPP ($i)] remote-address; ];
            :set tempString  ("$tempString"."$tempName".":"."%0A"." > "."$tempComment"." - "."$tempAddress"."%0A");
            #---UP-TIME
            :if ($2 = "time" || $3 = "time" || $4 = "time" || $5 = "time" || $6 = "time") do={
                :if ([/ppp active find comment=$tempComment]) do={
                    :set tempArgument [/ppp active get [find comment=$tempComment] uptime; ];
                } else={
                    :set tempArgument "inactive";
                }
                :set tempString ("$tempString"." > up: "."$tempArgument"."%0A");
            }
            #---PASWORD
            :if ($2 = "pass" || $3 = "pass" || $4 = "pass" || $5 = "pass" || $6 = "pass") do={
                :foreach n in=$notAccessList do={ 
                    :if ($n = $tempComment) do={
                        :set tempArgument "denied";
                    } else={ :set tempArgument [/ppp secret get [:pick $clientPPP ($i)] password;] }
                }
                :set tempString ("$tempString"." > pass: "."$tempArgument"."%0A");
            } 
            #---LAST-CALLER-ID
            :if ($2 = "call" || $3 = "call" || $4 = "call" || $5 = "call" || $6 = "call") do={
                :set tempArgument [/ppp secret get [:pick $clientPPP ($i)] last-caller-id;]
                :set tempString ("$tempString"." > last-caller: "."$tempArgument"."%0A");
            }
            #---Netwatch
            :if ($2 = "netwatch" || $3 = "netwatch" || $4 = "netwatch" || $5 = "netwatch" || $6 = "netwatch") do={
                :if ( [ /tool netwatch find comment="$tempComment"; ] ) do={
                    :if ( [ /tool netwatch find comment="$tempComment" disabled=no; ] ) do={
                        :set tempString ("$tempString"." > Netwatch existed and enabled"."%0A");
                    } else={
                        :set tempString ("$tempString"." > Netwatch existed and disabled"."%0A");
                    }
                } else={
                    :set tempString ("$tempString"." > Netwatch not existed"."%0A");
                }
            }
            #---NAT
            :if ($2 = "nat" || $3 = "nat" || $4 = "nat" || $5 = "nat" || $6 = "nat") do={
                :if ( [ /ip firewall nat find comment="$tempComment"; ] ) do={
                    :local port [ /ip firewall nat get [find comment="$tempComment"] dst-port; ]
                    :if ( [ /ip firewall nat find comment="$tempComment" disabled=no; ] ) do={
                        :set tempString ("$tempString"." > NAT existed and enabled; Port: "."$port"."%0A");
                    } else={
                        :set tempString ("$tempString"." > NAT existed and disabled; Port: "."$port"."%0A");
                    }
                } else={
                        :set tempString ("$tempString"." > NAT not existed"."%0A");
                }
            }
        }
        :return $tempString;
    } else={ :return "PPP print error: \"$nameClient\" not found! Try again..."; }
}

#---Function of Enabling Disabling Removing PPP-client information
:local EnableDisableRemove do={
    :local action $1;
    :local target $2;
    :local nameClient $3;
    :local clientPPP [ /ppp secret find (comment="$nameClient") ];
    if ([:len $clientPPP] > 0) do={
        :local clientComment [ /ppp secret get $nameClient comment; ];
        :if ($target = "netwatch") do={
            :if [ /tool netwatch find comment="$clientComment"; ] do={
                [:parse ("tool netwatch $action [find comment=$clientComment]")];
                :return ($nameClient." netwatch successfully "."$action"."d"); 
            } else={ :return "$target error: \"$nameClient\" not exist! Try again..."; }
        } 
        :if ($target = "nat") do={
            :if [ /ip firewall nat find comment="$clientComment"; ] do={
                [:parse ("ip firewall nat $action [find comment=$clientComment]")];
                :return ($nameClient." nat successfully "."$action"."d"); 
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
    if ( [/ppp secret find (comment="$nameClient")] = "") do={ :return "Set error: client \"$nameClient\" not found! Try again..."; }
    :local clientComment [ /ppp secret get $nameClient comment; ];
    :local clientAddress [ /ppp secret get $nameClient remote-address; ];
    :local externalAddress [ /ip address get [find interface="ether1"] address; ];
    :set externalAddress [:pick $externalAddress 0 [:find $externalAddress "/" -1]];
    #--- Nat Set
    :if ( ($target = "nat") && ([:len $port] > 0) ) do={
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
        :if ( $action = "set" && [ /ip firewall nat find comment="$clientComment"; ] = 0 ) do={ 
            :return "$target set error: \"$nameClient\" not exist! Try again..."; 
        }
        :if ( $action = "add" && [ /ip firewall nat find comment="$clientComment"; ] ) do={ 
            :return "$target set error: \"$nameClient\" already exist! Try again..."; 
        }
        :do {
            :if ( $action = "set" ) do={ 
                [:parse ("ip firewall nat $action [find comment=$clientComment] dst-port=$port protocol=$protocol")];
                :return ($nameClient." nat $port/$protocol successfully set"); 
            } 
            :if ( $action = "add" ) do={ 
                [:parse ("ip firewall nat $action action=dst-nat chain=dstnat comment=$clientComment dst-address=$externalAddress \
                    dst-port=$port in-interface=ether1 protocol=$protocol to-addresses=$clientAddress")];
                :return ($nameClient." nat $port/$protocol successfully added"); 
            }
        } on-error={ :return "$target $action error: wrong protocol or port! Try again..."; }
    }
    :if ( $target = "pass" ) do={
        :if ( [:len $port] = 0 ) do={ :return ("Password is empty. Try again..."); }
        [:parse ("ppp secret $action [find comment=$clientComment] password=$port")];
        :return ("PPP: " . $nameClient . " password successfully changed."); 
    }
    :return "Set error: option \"$target\" or port not recognized! Try again..."; 
}

#---MAIN---#
#---Help
:if ($0 = null || $1 = null) do={ $Help; :return; }
#---Print
:if ($0 = "print") do={ $SendMsg [ $Print $1 $2 $3 $4 $5 $6 ]; :return []; } 
#---Rename
:if ($0 = "rename") do={
    :if ($2 != null) do={
        $SendMsg [ $Rename $1 $2 ]; return [];
    } else={
        $SendMsg ("PPP $0 error: not enough arguments. Try again..."); :return [];
    } 
} 
#---Enable, disable, remove
:if ($0 = "enable" || $0 = "disable" || $0 = "remove") do={
    :if ($2 != null) do={ 
        $SendMsg [ $EnableDisableRemove $0 $1 $2 ]; return [];
    } else={
        $SendMsg ("PPP $0 error: not enough arguments. Try again..."); :return []; 
    } 
} 
#---Set
:if ($0 = "set" || $0 = "add") do={
    :if ($2 != null) do={ 
        $SendMsg [ $SetAdd $0 $1 $2 $3 ]; return [];
    } else={
        $SendMsg ("PPP $0 error: not enough arguments. Try again..."); :return []; 
    } 
} 
$SendMsg "PPP error: unknown option. Try again...";
