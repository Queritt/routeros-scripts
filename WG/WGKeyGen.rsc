# WGKeyGen
# Excluding special symbol: "+/"
# 0.1
# 2022/10/14
#---Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    [[:parse [/system script get TG source]] Text=("$nameID:"."%0A"."$1")];
}
:local Gen do={
    :local genName "wireguard-keygen";
    /interface wireguard set $genName private-key="";
    :local privateKey [/interface wireguard get $genName private-key];
    :local publicKey [/interface wireguard get $genName public-key];
    :local tmpStr "";
    :for i from=0 to=([:len $privateKey]-1) step=1 do={
        :local char [:pick $privateKey $i];
        :if ( $char = "+" || $char = "/") do={ return null; } else={ :set tmpStr ($tmpStr.$char); } 
    };
    :set privateKey $tmpStr;
    :local tmpStr "";
    :for i from=0 to=([:len $publicKey]-1) step=1 do={
        :local char [:pick $publicKey $i];
        :if ( $char = "+" || $char = "/") do={ return null; } else={ :set tmpStr ($tmpStr.$char); } 
    };
    :set publicKey $tmpStr;
    :return {$privateKey; $publicKey};
}
#--Main
:local action $0;
:if ( [ :len [/interface wireguard find name="wireguard-keygen"] ] = 0) do={
    /interface wireguard add name="wireguard-keygen" listen-port=0;
}
:local state null;
:while ($state = "null") do={
    :set state [$Gen];
}
:if ( $action = "print" ) do={  
    :local key1 [:pick $state 0];
    :local key2 [:pick $state 1];
    :local textMsg ("Key pair: " . "%0A" . " > Pvt: "  . "$key1" . "%0A" . " > Pub: " . "$key2");
    $SendMsg $textMsg;
} else={ :return $state; }
