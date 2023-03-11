# Antifilter
# 0.1
# 2022/09/21
:local filterName "antifilter.download";
#---Function of sending message to telegram bot
:local SendMsg do={
    :local  nameID [ /system identity get name; ];
    [[:parse [/system script get TG source]] Text=("$nameID:"."%0A"."$1")];
}
:if ($0 = "on" || $0 = "On") do={
    :if ( [/routing bgp peer get [find comment="$filterName"] disabled] ) do={ 
        /tool netwatch enable [find comment="$filterName"];
    } else={ $SendMsg "Antifilter already enabled or not exist."; }
    :return [];
} 
:if ($0 = "off" || $0 = "Off") do={
    :if ( ![/routing bgp peer get [find comment="$filterName"] disabled]) do={        
        /tool netwatch disable [ find comment="$filterName" ];
        /routing bgp peer disable [ find comment="$filterName" ];
        $SendMsg "Antifilter disabled by script.";
    } else={ $SendMsg "Antifilter already disabled or not exist."; }
    :return [];
} 
$SendMsg ("Antifilter options: " . "%0A" . " > on/off");
