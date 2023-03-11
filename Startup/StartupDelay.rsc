# Startup Delay
# 0.20
# 2022/10/22
:local dateNow [/system clock get date];
:local delayPPPFailover 10;
:local delayISPFailover 2;

:local Delay do={
    :local timeNow [/system clock get time];
    :local timeH ([:pick $timeNow 0 2] + $deltaH);
    :local timeM ([:pick $timeNow 3 5] + $deltaM);
    #:local timeS ([:pick $timeNow 6 8] + $deltaS);
    :set timeM ($timeM + $a);
    :if ($timeM >= 60) do={
        :set timeM ($timeM - 60);
        :set timeH ($timeH + 1);
        :if ($timeH >= 24) do={ :set timeM ($timeH - 24); }
    }
    :return ("$timeH".":"."$timeM".":"."00");
}

/system scheduler set PPPFailover start-time=[$Delay a=$delayPPPFailover] start-date=$dateNow;
/system scheduler set ISPFailover start-time=[$Delay a=$delayISPFailover] start-date=$dateNow;
