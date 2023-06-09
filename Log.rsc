## Log
## 0.18
## 2023/05/11
## Fix past log time 

:local SendMsg do={
    :if ([:len $1] != 0) do={
        :local nameID [/system identity get name;];
        :local outMsg $1;
        :local outMsgSplit;
        :local logPart;
        :local tmpChar;
        :local maxLength (4096 - [:len ("/$nameID ")] - [:len ("(message 99 of 99):"."%0A")]);
        :local foundChar;
        :local counter;
        :if ([:len ("/$nameID:"."%0A"."$outMsg")] > 4096) do={
            :while ([:len $outMsg] > 0) do={
                :if ([:len $outMsg] > $maxLength) do={
                    :set foundChar -1;
                    :set counter ($maxLength -3);
                    :while ($foundChar = -1 and $counter > -1) do={
                        :set tmpChar [:pick $outMsg $counter ($counter +3)];
                        :if ($tmpChar = "%0A") do={:set foundChar $counter;};
                        :set counter ($counter -1);
                    }
                    :if ($foundChar > -1) do={
                        :set outMsgSplit ($outMsgSplit, [:pick $outMsg 0 ($foundChar +3)]);
                        :set $outMsg [:pick $outMsg ($foundChar +3) [:len $outMsg]];
                    } else={
                        :set outMsgSplit ($outMsgSplit, [:pick $outMsg 0 $maxLength]);
                        :set $outMsg [:pick $outMsg $maxLength [:len $outMsg]];
                    }
                } else={:set outMsgSplit ($outMsgSplit, $outMsg); :set $outMsg "";};
            }
        } else={:set outMsgSplit {$outMsg}};
        :set logPart [:len $outMsgSplit];
        :for n from=0 to=([:len $outMsgSplit] -1) do={
            [[:parse [/system script get TG source]] \
            Text=("/$nameID "."(message ".($n+1)." of $logPart):"."%0A".[:pick $outMsgSplit $n])]; delay 2s;};
    }
}

:local Help do={
    :local help ("Log option: "."%0A". \
        " > print [all; head; tail; find; time]"."%0A". \
        " > reset"."%0A". \
        " > set [1k-10k]")
    :return $help;
}

:local ResetLog do={
    :local curLen [/system logging action get memory memory-lines];
    /system logging action set memory memory-lines=1; 
    /system logging action set memory memory-lines=$curLen; 
    :return (" Log reseted.");
}

:local SetLog do={
    :do {
        :if ($1~"[0-9]" && $1 >=1000 && $1 <= 10000 && $1 != [/system logging action get memory memory-lines]) do={
            /system logging action set memory memory-lines=$1; 
            :return (" Log: lines set as \"$1\".");
        } else={:return (" Log: \"$1\" not in range or not number or quals last value, try again...")};
    } on-error={:return (" Log set: something went wrong, try again...")};
}

:local PrintLog do={

    # Function of searching comments for MAC-address
    # https://forummikrotik.ru/viewtopic.php?p=73994#p73994
    :local FindMacAddr do={
        :if ($1~"[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]:[0-F][0-F]") do={
            :foreach idx in=[/ip dhcp-server lease find disabled=no] do={
                :local mac [/ip dhcp-server lease get $idx mac-address];
                :if ($1~"$mac") do={:return ("$1 [$[/ip dhcp-server lease get $idx address]/$[/ip dhcp-server lease get $idx comment]].")};
            }
            :foreach idx in=[/interface bridge host find] do={
                :local mac [/interface bridge host get $idx mac-address];
                :if ($1~"$mac") do={:return ("$1 [$[/interface bridge host get $idx on-interface]].")};
            }
        }
        :return ($1);
    }

    # Function of converting CP1251 to UTF8
    # https://forummikrotik.ru/viewtopic.php?p=81457#p81457
    :local CP1251toUTF8 do={
        :local cp1251 [:toarray {
            "\20";"\01";"\02";"\03";"\04";"\05";"\06";"\07";"\08";"\09";"\0A";"\0B";"\0C";"\0D";"\0E";"\0F";\
            "\10";"\11";"\12";"\13";"\14";"\15";"\16";"\17";"\18";"\19";"\1A";"\1B";"\1C";"\1D";"\1E";"\1F";\
            "\21";"\22";"\23";"\24";"\25";"\26";"\27";"\28";"\29";"\2A";"\2B";"\2C";"\2D";"\2E";"\2F";"\3A";\
            "\3B";"\3C";"\3D";"\3E";"\3F";"\40";"\5B";"\5C";"\5D";"\5E";"\5F";"\60";"\7B";"\7C";"\7D";"\7E";\
            "\C0";"\C1";"\C2";"\C3";"\C4";"\C5";"\C6";"\C7";"\C8";"\C9";"\CA";"\CB";"\CC";"\CD";"\CE";"\CF";\
            "\D0";"\D1";"\D2";"\D3";"\D4";"\D5";"\D6";"\D7";"\D8";"\D9";"\DA";"\DB";"\DC";"\DD";"\DE";"\DF";\
            "\E0";"\E1";"\E2";"\E3";"\E4";"\E5";"\E6";"\E7";"\E8";"\E9";"\EA";"\EB";"\EC";"\ED";"\EE";"\EF";\
            "\F0";"\F1";"\F2";"\F3";"\F4";"\F5";"\F6";"\F7";"\F8";"\F9";"\FA";"\FB";"\FC";"\FD";"\FE";"\FF";\
            "\A8";"\B8";"\B9"}];
        :local utf8 [:toarray {
            "0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"000A";"0020";"0020";"000D";"0020";"0020";\
            "0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";"0020";\
            "0021";"0022";"0023";"0024";"0025";"0026";"0027";"0028";"0029";"002A";"002B";"002C";"002D";"002E";"002F";"003A";\
            "003B";"003C";"003D";"003E";"003F";"0040";"005B";"005C";"005D";"005E";"005F";"0060";"007B";"007C";"007D";"007E";\
            "D090";"D091";"D092";"D093";"D094";"D095";"D096";"D097";"D098";"D099";"D09A";"D09B";"D09C";"D09D";"D09E";"D09F";\
            "D0A0";"D0A1";"D0A2";"D0A3";"D0A4";"D0A5";"D0A6";"D0A7";"D0A8";"D0A9";"D0AA";"D0AB";"D0AC";"D0AD";"D0AE";"D0AF";\
            "D0B0";"D0B1";"D0B2";"D0B3";"D0B4";"D0B5";"D0B6";"D0B7";"D0B8";"D0B9";"D0BA";"D0BB";"D0BC";"D0BD";"D0BE";"D0BF";\
            "D180";"D181";"D182";"D183";"D184";"D185";"D186";"D187";"D188";"D189";"D18A";"D18B";"D18C";"D18D";"D18E";"D18F";\
            "D001";"D191";"2116"}];
        :local convStr ""; 
        :local code "";
        :for i from=0 to=([:len $1]-1) do={
            :local symb [:pick $1 $i ($i+1)]; 
            :local idx [:find $cp1251 $symb];
            :local key ($utf8->$idx);
            :if ([:len $key]!=0) do={
                :set $code ("%$[:pick ($key) 0 2]%$[:pick ($key) 2 4]");
                :if ([pick $code 0 3]="%00") do={:set $code ([:pick $code 3 6])};
            } else={:set code ($symb)}; 
            :set $convStr ($convStr.$code);
        }
        :return ($convStr);
    }

    # --function convert string to lowstring by Osama, modified Sertik--
    :local fsLowStr do={
        :local fsLowerChar do={
            :local "fs_lower" "0123456789abcdefghijklmnopqrstuvwxyz";
            :local "fs_upper" "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            :local pos [:find $"fs_upper" $1]
                :if ($pos > -1) do={:return [:pick $"fs_lower" $pos];}
                :return $1}
    :local result ""; :local in $1
        :for i from=0 to=([:len $in] - 1) do={
            :set result ($result . [$fsLowerChar [:pick $in $i]])}
            :return $result;
    }

    :local EpochTime do={
        :local ds $1;
        :local ts;
        :local curDate [/system clock get date];
        :local curYear [:pick $curDate 7 [:len $curDate]];
        ## Case date(mon/day/year) + time
        :if ([:len $1]>19) do={:set ds "$[:pick $1 0 11]"; :set ts [:pick $1 12 20];};
        ## Case date(mon/day) + time
        :if ([:len $1]>8 && [:len $1]<20) do={:set ds "$[:pick $1 0 6]/$curYear"; :set ts [:pick $1 7 15];};
        ## Case time
        :if ([:len $1]=8) do={:set ds $curDate; :set ts $1;};
        :local months;
        :if ((([:pick $ds 9 11]-1)/4)!=(([:pick $ds 9 11])/4)) do={
            :set months {"an"=0;"eb"=31;"ar"=60;"pr"=91;"ay"=121;"un"=152;"ul"=182;"ug"=213;"ep"=244;"ct"=274;"ov"=305;"ec"=335};
        } else={
            :set months {"an"=0;"eb"=31;"ar"=59;"pr"=90;"ay"=120;"un"=151;"ul"=181;"ug"=212;"ep"=243;"ct"=273;"ov"=304;"ec"=334};
        }
        :set ds (([:pick $ds 9 11]*365)+(([:pick $ds 9 11]-1)/4)+($months->[:pick $ds 1 3])+[:pick $ds 4 6]);
        :set ts (([:pick $ts 0 2]*3600)+([:pick $ts 3 5]*60)+[:pick $ts 6 8]);
        :return ($ds*86400+$ts+946684800-[/system clock get gmt-offset]);
    }  

    :do {
        :local option $1;
        :local lineNum $2;
        :local message;
        :local time;
        :local topic;
        :local outMsg (" Log:"."\n");
        :local startBuf [:toarray [/log find]];
        :local tmpStartBuf;
        ## Deleting unwanted message
        :foreach n in=$startBuf do={
            :set topic [/log get $n topics];
            :set message [/log get $n message];
            :if ($topic~"account" or $message~"script|changed by|added by|removed by") do={:put ""} else={:set tmpStartBuf ($tmpStartBuf, $n)}; 
        }
        :set startBuf $tmpStartBuf;
        :if ([:len $startBuf]=0) do={:return (" Log: items not found.");};
        :local start 0;
        :local end ([:len $startBuf] -1);
        ## Options
        :if ([:typeof $option]="nothing" || $option~"all|head|tail|find|time") do={:put ""} else={:return (" Log: "."option \"$option\""." - not recognized, try again...");}; 
        ## Line Numbers
        :if ([:typeof $lineNum]="nothing" || $option~"find" || $option~"time" || $lineNum~"[1-9]") do={:put ""} else={:return (" Log: "."\"$lineNum\""." - not allowed numbers, try again...");}; 
        ## FIND
        :if ($option = "find") do={
            :if ([:len $lineNum] < 3) do={:return (" Log: find requires at least 3 symbols.");};
            :set tmpStartBuf ({});
            :set lineNum [$fsLowStr $lineNum];
            :foreach n in=$startBuf do={
                :set message [$fsLowStr [/log get $n message]];
                :if ($message~$lineNum) do={:set tmpStartBuf ($tmpStartBuf, $n);}; 
            }
            :if ([:len $tmpStartBuf] = 0) do={:return (" Log: search \"$lineNum\" not found.");};
            :set startBuf $tmpStartBuf;
            :set end ([:len $startBuf] -1);   
        };
        ## NOTHING
        :if ([:typeof $option] = "nothing") do={:if ([:len $startBuf] >= 50) do={:set start ([:len $startBuf] - 50);}};
        ## HEAD
        :if ($option = "head") do={
            :if ([:typeof $lineNum] = "nothing") do={:if ([:len $startBuf] >= 20) do={:set end 19;}};
            :if ($lineNum~"[1-9]") do={:if ($lineNum < [:len $startBuf]) do={:set end ($lineNum -1);}};
        };
        ## TAIL
        :if ($option = "tail") do={
            :if ([:typeof $lineNum] = "nothing") do={:if ([:len $startBuf] >= 20) do={:set start ([:len $startBuf] - 20);}};
            :if ($lineNum~"[1-9]") do={:if ($lineNum < [:len $startBuf]) do={:set start ([:len $startBuf] - $lineNum)};};
        };
        ## TIME
        :if ($option = "time") do={
            :if ([:typeof $lineNum]="nothing") do={:set $lineNum 1};
            :if (([:len $lineNum] > 0) && $lineNum~"[1-9]") do={:put ""} else={:return (" Log: time requires only numbers, try again...");}; 
            :local curDate [/system clock get date];
            :local curTime [/system clock get time];
            :local curEpochTime [$EpochTime ($curDate." ".$curTime)];
            :local printEpochTime ($curEpochTime - ($lineNum*3600));
            :local lenStartBuf [:len $startBuf];
            :local firstLineEpochTime [$EpochTime [/log get [:pick $startBuf 0] time]];
            :local lastLineEpochTime [$EpochTime [/log get [:pick $startBuf ($lenStartBuf -1)] time]];
            :local outOfLog false;
            :if ($printEpochTime < $firstLineEpochTime) do={:set outOfLog true};
            :if ($lastLineEpochTime < $printEpochTime) do={:return (" Log: items in $lineNum"."hr not found.");};
            :if (!$outOfLog) do={
                :local count 0;
                :set start -1;
                :while ($start < 0 && ($count < $lenStartBuf)) do={
                    :set time [$EpochTime [/log get [:pick $startBuf $count] time]];
                    :if ($time >= $printEpochTime) do={:set start $count};
                    :set count ($count+1);
                }
            }
        }
        :for n from=$start to=$end do={
            :set message [$FindMacAddr [/log get [:pick $startBuf $n] message]];
            :set time [/log get [:pick $startBuf $n] time];
            :set outMsg ($outMsg."> ".$time.": ".$message."\n");
        }
        :return [$CP1251toUTF8 $outMsg];
    } on-error={:return " Log: something went wrong, try again..."};
}
:local action $0;
:if ($action = "help" || $action = "Help") do={$SendMsg [$Help]; :return [];};
:if ($action = "print") do={$SendMsg [$PrintLog $1 $2]; :return [];};
:if ($action = "reset") do={$SendMsg [$ResetLog]; :return [];};
:if ($action = "set")   do={$SendMsg [$SetLog $1]; :return [];};
$SendMsg [$Help];
