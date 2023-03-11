# Device status view script
# Script uses ideas by Enternight, Jotne, Sertik, drPioneer
# https://forummikrotik.ru/viewtopic.php?p=84984#p84984
# tested on ROS 6.49.5
# updated 2022/04/27
# modified 2022/05/31

:do {
    # Digit conversion function via SI-prefix
    # How to use: :put [$NumSiPrefix 648007421264];
    :local NumSiPrefix do={
        :local inp [:tonum $1];
        :local cnt 0;
        :while ($inp > 1024) do={
            :set $inp ($inp/1024);
            :set $cnt ($cnt+1);
        }
        :return ($inp.[:pick [:toarray "B,Kb,Mb,Gb,Tb,Pb,Eb,Zb,Yb"] $cnt]);
    }

    # Defining variables
    :local hddTotal [/system resource get total-hdd-spac];
    :local hddFree  [/system resource get free-hdd-space];
    :local badBlock [/system resource get bad-blocks];
    :local memTotal [/system resource get total-memory];
    :local memFree  [/system resource get free-memory];
    :local cpuZ     [/system resource get cpu-load];
    :local currFW   [/system routerbo get upgrade-firmwa];
    :local upgrFW   [/system routerbo get current-firmwa];
    :if ([/system resource get board-name]!="CHR" && [/system resource get board-name]!="x86") do={
        :local tempC [/system health get temperature];
        :local volt  [/system health get voltage];
    }
    :local smplVolt ($volt/10);
    :local lowVolt  (($volt-($smplVolt*10))*10);
    :local inVolt   ("$smplVolt.$[:pick $lowVolt 0 3]");
    :local message  ("Health report:"."%0A"."ID $[system identity get name]"."%0A");


    #General information
    :set   message  ("$message"."Uptime $[system resource get uptime]");
    :set   message  ("$message"."%0A"."Model $[system resource get board-name]");
    :set   message  ("$message"."%0A"."ROS $[system resource get version]");
    :if ($currFW != $upgrFW) do={set message ("$message \r\n*FW not updated*")}
    :set   message  ("$message"."%0A"."Arch $[/system resource get arch]");
    :set   message  ("$message"."%0A"."CPU $[/system resource get cpu]");
    :set   hddFree  ($hddFree/($hddTotal/100));
    :set   memFree  ($memFree/($memTotal/100));
    :if ($cpuZ < 90) do={:set message ("$message"."%0A"."CPU load $cpuZ%");
    } else={:set message ("$message"."%0A"."*Large CPU usage $cpuZ%*"."%0A")}
    :if ($memFree > 17) do={:set message ("$message"."%0A"."Mem free $memFree%");
    } else={:set message ("$message"."%0A"."*Low free mem $memFree%*")}
    :if ($hddFree > 6) do={:set message ("$message"."%0A"."Disk free $hddFree%");
    } else={:set message ("$message"."%0A"."*Low free Disk $hddFree%*")}
    :if ([:len $badBlock] > 0) do={
        :if ($badBlock = 0) do={:set message ("$message"."%0A"."Bad blocks $badBlock%");
        } else={:set message ("$message"."%0A"."*Present bad blocks $badBlock%*")}
    }
    :if ([:len $volt] > 0) do={
        :if ($smplVolt > 4 && $smplVolt < 50) do={:set message ("$message"."%0A"."Voltage $inVolt V");
        } else={:set message ("$message"."%0A"."*Bad voltage $inVolt V*")}
    }
    :if ([:len $tempC] > 0) do={
        :if ($tempC > 10 && $tempC < 40) do={:set message ("$message"."%0A"."Temp $tempC C");
        } else={:set message ("$message"."%0A"."*Abnorm temp $tempC C*")}
    }

    # Gateways information
    :local routeISP [/ip route find dst-address=0.0.0.0/0];
    :if ([:len $routeISP] > 0) do={
        :local gwList [:toarray ""];
        :local count 0;
        :foreach inetGate in=$routeISP do={
            :local gwStatus [:tostr [/ip route get $inetGate gateway-status]];
            :if ([:len $gwStatus] > 0) do={
                :if ([:len [:find $gwStatus "unreachable"]]=0 && [:len [:find $gwStatus "inactive"]]=0) do={

                    # Formation of interface name
                    :local ifaceISP "";
                    :foreach idName in=[/interface find] do={
                        :local ifName [/interface get $idName name];
                        :if ([:len [find key=$ifName in=$gwStatus]] > 0) do={:set ifaceISP $ifName}
                    }
                    :if ([:len $ifaceISP] > 0) do={

                        # Checking the interface for entering the Bridge
                        :if ([:len [/interface bridge find name=$ifaceISP]] > 0) do={
                            :local ipAddrGW [:tostr [/ip route get $inetGate gateway]];
                            :if ([:find $ipAddrGW "%"] > 0) do={
                                :set $ipAddrGW [:pick $ipAddrGW ([:len [:pick $ipAddrGW 0 [:find $ipAddrGW "%"]] ] +1) [:len $ipAddrGW]];
                            }
                            :if ($ipAddrGW~"[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}") do={
                                :local mcAddrGate [/ip arp get [find address=$ipAddrGW interface=$ifaceISP] mac-address];
                                :if ($mcAddrGate~"[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]") do={
                                    :set ifaceISP [/interface bridge host get [find mac-address=$mcAddrGate] interface];
                                } else={:set ifaceISP ""}
                            } else={:set ifaceISP ""}
                        }
                        :if ([:len $ifaceISP] > 0) do={

                            # Checking the repetition of interface name
                            :local checkIf [:len [find key=$ifaceISP in=$gwList]];
                            :if ($checkIf = 0) do={
                                :set ($gwList->$count) $ifaceISP;
                                :set count ($count+1);
                                :local gbRxReport [$NumSiPrefix [/interface get $ifaceISP rx-byte]];
                                :local gbTxReport [$NumSiPrefix [/interface get $ifaceISP tx-byte]];
                                :set message ("$message"."%0A"."Traffic via:"."%0A"."'$ifaceISP'"."%0A"."Rx/Tx $gbRxReport/$gbTxReport");
                            }
                        }
                    }
                }
            }
        }
    } else={:set message ("$message"."%0A"."WAN iface not found")}

    # Output of message
    [[:parse [/system script get TG source]] Text=$message]
} on-error={:log warning ("Error, can't show health status")}
