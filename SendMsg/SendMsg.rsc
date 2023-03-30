:local SendMsg do={
    :local nameID [/system identity get name;];
    :if ([:len $1] != 0) do={[[:parse [/system script get TG source]] Text=("/$nameID:"."%0A"."$1")];};
}
