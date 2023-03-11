# WirelessFreqReset
# 0.1
# 2023/01/22
:if ( [/interface wireless registration-table find interface~"wlan1"] ) do={ :return []; } else={
    /interface wireless disable wlan1;
    /interface wireless enable wlan1;
    /log info "wlan1: no registered clients. Frequency reseted.";
}
