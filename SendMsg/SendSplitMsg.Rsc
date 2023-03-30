:local SendMsg do={
    :if ([:len $1] != 0) do={
        :local nameID [/system identity get name;];
        :local outMsg $1;
        :local outMsgSplit;
        :local cnt 1;
        :local logPart ([:len ("/$nameID:"."%0A"."$outMsg")] / 4096 + 1);
        :if ([:len ("/$nameID:"."%0A"."$outMsg")] > 4096) do={
            :while ([:len $outMsg] > 0) do={
                :set outMsg ("/$nameID "."(message $cnt of $logPart):"."%0A"."$outMsg");
                :if ([:len $outMsg] > 4096) do={
                    :set outMsgSplit ($outMsgSplit, [:pick $outMsg 0 4096]);
                    :set $outMsg [:pick $outMsg 4096 [:len $outMsg]];
                } else={:set outMsgSplit ($outMsgSplit, $outMsg); :set $outMsg "";};
                :set cnt ($cnt +1);
            }
        } else={:set outMsgSplit ("/$nameID:"."%0A"."$outMsg")};
        :foreach n in=$outMsgSplit do={[[:parse [/system script get TG source]] Text=($n)];};
    }
}
