## 0.10
## 2023/05/31
:local sysname [/system identity get name];
:local scriptArray [ :toarray [ /system script find; ] ];
:local functionArray [ :toarray [ /system script environment find; ] ];

:local tempScriptList;
:local tempFunctionList;
:local tempString;

:set tempScriptList ("\"$sysname\" scripts: "."%0A");
:for i from=0 to=([:len $scriptArray] - 1) do={
        :set tempString [ /system script get [:pick $scriptArray ($i)] name; ];
        :set tempScriptList  ("$tempScriptList"."$tempString"."%0A");
}
:set tempFunctionList ("$tempScriptList"."%0A"."\"$sysname\" functions: "."%0A")
:for i from=0 to=([:len $functionArray] - 1) do={
        :set tempString [ /system script environment get [:pick $functionArray ($i)] name; ];
        :set tempFunctionList ("$tempFunctionList"."$tempString"."%0A");
}
## Sending message
[[:parse [/system script get TG source]] Text=$tempFunctionList];
