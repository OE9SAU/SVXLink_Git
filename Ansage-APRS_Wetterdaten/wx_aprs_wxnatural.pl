#!/usr/bin/perl

########################################
# SVXLink APRS Wetteransage Script
# v1.0 - OE9SAU - 07/2026
# v1.1 - OE9SAU - add 24h rain - 08/2026
########################################

use strict;
use warnings;
use LWP::UserAgent;
use XML::Simple;

############################
# Konfiguration
############################

my $call   = "YOUR WX-CALL";
my $apikey = "YOUR WX-CALL_API_KEY";

my $outfile="/tmp/wx_oe9xvi.tcl";
my $pressure_file="/tmp/wx_pressure_last.txt";

############################
# Windrichtung bestimmen
############################

sub wind_dir {

my $deg = shift;

return "Nord" if ($deg >= 337 || $deg < 22);
return "Nordost" if ($deg < 67);
return "Ost" if ($deg < 112);
return "Suedost" if ($deg < 157);
return "Sued" if ($deg < 202);
return "Suedwest" if ($deg < 247);
return "West" if ($deg < 292);
return "Nordwest";

}

############################
# Tausenderzahlen
############################

sub speak_pressure {

    my ($WX, $pressure) = @_;

    if ($pressure >= 1000) {

        my $rest = $pressure - 1000;

        print $WX "playMsg \"WxNatural\" \"eintausend\";\n";

        if ($rest > 0) {
            print $WX "playNumber $rest;\n";
        }

    }
    else {
        print $WX "playNumber $pressure;\n";
    }
}

############################
# APRS Anfrage
############################

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->agent("SVXLink WX");

my $url="https://api.aprs.fi/api/get?name=$call&what=wx&apikey=$apikey&format=xml";

my $res=$ua->get($url);

############################
# Fehlerfall
############################

unless($res->is_success){

open(my $WX,">",$outfile) or die "cannot write";

print $WX "playMsg \"WxNatural\" \"Wetterdaten_momentan_nicht_verfuegbar\";\n";

close($WX);
exit;

}

############################
# XML lesen
############################

my $xml=XMLin($res->decoded_content);
my $wx=$xml->{entries}->{entry};


my $temp = sprintf("%.1f", $wx->{temp}//0);
my $humidity=int($wx->{humidity}//0);
my $pressure=int($wx->{pressure}//0);

my $wind = int((($wx->{wind_speed}//0) * 3.6) + 0.5);
my $gust = int((($wx->{wind_gust}//0) * 3.6) + 0.5);

my $rain   = sprintf("%.1f", $wx->{rain_1h}//0);
my $rain24 = sprintf("%.1f", $wx->{rain_24h}//0);

my $dir=int($wx->{wind_direction}//0);
my $timestamp=$wx->{time}//time;

############################
# Messzeit
############################

my ($sec,$min,$hour) = (localtime($timestamp))[0,1,2];

############################
# Luftdrucktrend
############################

my $old_pressure=0;

if(-e $pressure_file){
    if (open(my $F,"<",$pressure_file)){
        $old_pressure=<$F>;
        chomp($old_pressure);
        close($F);
    }
}

my $trend = "stable";

if ($old_pressure > 0) {

    my $diff = $pressure - $old_pressure;

    if ($diff >= 1) {
        $trend = "rising";
    }
    elsif ($diff <= -1) {
        $trend = "falling";
    }
    else {
        $trend = "stable";
    }

}
if (open(my $F,">",$pressure_file)){
    print $F $pressure;
    close($F);
}

############################
# TCL Datei erzeugen
############################

open(my $WX,">",$outfile) or die "cannot write";

# Einleitung
print $WX "playMsg \"WxNatural\" \"Aktuelle_Wetterdaten_von\";\n";
print $WX "spellWord $call;\n";

print $WX "playSilence 200;\n";

# Messzeit
print $WX "playMsg \"WxNatural\" \"Stand\";\n";
print $WX "playNumber $hour;\n";
print $WX "playMsg \"WxNatural\" \"Uhr\";\n";

if ($min > 0) {
    print $WX "playNumber $min;\n";
}

print $WX "playSilence 300;\n";

############################
# Temperatur + Feuchte (ein Satz)
############################

print $WX "playMsg \"WxNatural\" \"Die_Temperatur_betraegt\";\n";

if ($temp < 0) {
    print $WX "playMsg \"MetarInfo\" \"minus\";\n";
    print $WX "playNumber ", abs($temp), ";\n";
} else {
    print $WX "playNumber $temp;\n";
}

print $WX "playMsg \"MetarInfo\" \"unit_degrees\";\n";

print $WX "playMsg \"WxNatural\" \"bei_einer_Luftfeuchte_von\";\n";
print $WX "playNumber $humidity;\n";
print $WX "playMsg \"MetarInfo\" \"percent\";\n";

print $WX "playSilence 300;\n";

############################
# Luftdruck + Trend (ein Satz)
############################

print $WX "playMsg \"WxNatural\" \"Der_Luftdruck_betraegt\";\n";
#print $WX "playNumber $pressure;\n";
speak_pressure($WX, $pressure);
print $WX "playMsg \"MetarInfo\" \"unit_hPa\";\n";

#print $WX "playMsg \"WxNatural\" \"und_ist\";\n";

if($trend eq "rising"){
    print $WX "playMsg \"WxNatural\" \"und_ist_steigend\";\n";
}
elsif($trend eq "falling"){
    print $WX "playMsg \"WxNatural\" \"und_ist_fallend\";\n";
}
else{
    print $WX "playMsg \"WxNatural\" \"und_ist_gleichbleibend\";\n";
}

print $WX "playSilence 300;\n";

############################
# Wind + Boen
############################

my $dir_text=wind_dir($dir);

if($wind < 5){

    print $WX "playMsg \"WxNatural\" \"Es_herrscht_Windstille\";\n";

    if($gust >= 8){
        print $WX "playMsg \"WxNatural\" \"In_Boen_bis_zu\";\n";
        print $WX "playNumber $gust;\n";
        print $WX "playMsg \"MetarInfo\" \"unit_kph\";\n";
    }

}
else{

    print $WX "playMsg \"WxNatural\" \"Der_Wind_kommt_aus\";\n";
    print $WX "playMsg \"WxNatural\" \"$dir_text\";\n";

    print $WX "playMsg \"WxNatural\" \"und_weht_mit\";\n";
    print $WX "playNumber $wind;\n";
    print $WX "playMsg \"MetarInfo\" \"unit_kph\";\n";

}

    print $WX "playSilence 300;\n";

############################
# Niederschlag
############################

if ($rain > 0) {

    # Regen letzte Stunde
    print $WX "playMsg \"WxNatural\" \"Niederschlag_in_der_letzten_Stunde\";\n";
    print $WX "playNumber $rain;\n";
    print $WX "playMsg \"MetarInfo\" \"unit_mm\";\n";

    # Regen letzte 24 Stunden
    if ($rain24 > 0) {
        print $WX "playMsg \"WxNatural\" \"Niederschlag_letzten_24h\";\n";
        print $WX "playNumber $rain24;\n";
        print $WX "playMsg \"MetarInfo\" \"unit_mm\";\n";
    }

}
elsif ($rain24 > 0) {

    # Momentan trocken, aber innerhalb der letzten 24h Regen
    print $WX "playMsg \"WxNatural\" \"Aktuell_wurde_kein_Niederschlag_gemessen\";\n";

    print $WX "playMsg \"WxNatural\" \"Niederschlag_letzten_24h\";\n";
    print $WX "playNumber $rain24;\n";
    print $WX "playMsg \"MetarInfo\" \"unit_mm\";\n";

}
else {

    # Weder letzte Stunde noch letzte 24h Regen
    print $WX "playMsg \"WxNatural\" \"Es_wurde_kein_Niederschlag_gemessen\";\n";

}

print $WX "playSilence 300;\n";

############################
# Ende
############################

print $WX "playMsg \"WxNatural\" \"Ende_der_Wetterdurchsage\";\n";

close($WX);

print "WX Update OK\n";
