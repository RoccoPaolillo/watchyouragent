;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variable and Breed declarations ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
extensions [csv]

globals
[
  giorno                ;; number of days so far
  energia-max          ;; energia capacity
  food-max           ;; energia collection capacity
  energia_richiesta          ;; amount of energia collected at each move
  refilling
  settimana
]

patches-own
[
  riserva-energetica       ;; amount of energia currently stored
]

breed [ units unit ]  ;; creation controlled by farmers
breed [ farmers farmer ] ;; created and controlled by clients


units-own
[
  energia_acquisita        ;; amount of energia collected from grazing
  owner#             ;; the user-id of the farmer who owns the unit
  riserve_unità
]

farmers-own
[
  user-id            ;; unique user-id, input by the client when they log in,
                     ;; to identify each student turtle
  n_mucche_comprate_a_settimana   ;; desired quantity of units to purchase
  revenue-lst        ;; list of each days' revenue collection
  capitale_totale       ;; total of past revenue, minus expenses
  capitale_totale-lst
  guadagno_giornaliero    ;; the revenue collected at the end of the last day
  contributo_comune_rigenerazione
  numero_mucche
  numero_mucche-lst
  n_mucche-lst
  contrcom-lst
  lost_cows
  lost_cows-lst
  units_to_buy
]


;;;;;;;;;;;;;;;;;;;;;
;; Setup Functions ;;
;;;;;;;;;;;;;;;;;;;;;

to startup
  hubnet-reset
  setup
end

;; initializes the display
;; but does not clear already created farmers
to setup
  setup-globals
  setup-patches
  clear-output
  clear-all-plots
  ask farmers
    [ reset-farmers-vars ]
   hubnet-broadcast "n_mucche_comprate_a_settimana" 1
   hubnet-broadcast "contributo_comune_rigenerazione" 0
  broadcast-system-info
end

;; initialize global variables
to setup-globals
  reset-ticks
  set giorno 0
  set settimana 0
  set energia-max 50
  set food-max 50
  set energia_richiesta (round (100 / (ritmo_cicli - 1)))
end

;; initialize energia supply for each patch
to setup-patches
  ask patches [
 set riserva-energetica 50
    color-patches
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;
;; Runtime Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;

to go
  ;; get command and data from client
  listen-to-clients

  every .1
  [

    if not any? farmers
    [
      user-message word "There are no farmers.  GO is stopping.  "
          "Press GO again when people have logged in."
      stop
    ]

tick

    ;; when not milking time
    ifelse (ticks mod ritmo_cicli) != 0
    [
      ask units
        [ graze ]
    ]
    [
      set giorno giorno + 1
      set settimana ceiling (giorno / 7)
      ask farmers
        [ profit-units ]
  ;    invest_capital ;; toene buy units
 ;     update-plots
    ;  ask farmers [set total-lst (lput revenue-lst total-lst)]
    if (ticks mod 7 = 0) [
        hubnet-broadcast "n_mucche_comprate_a_settimana" 1
        hubnet-broadcast "contributo_comune_rigenerazione" 0
        broadcast-system-info
        stop

        ]
    ]

    reset-patches


  ]



 broadcast-system-info

;  if (giorno != 0 and giorno mod 7 = 0) [stop]

  write_csv
end

;; goat move along the common looking for best patch of energia
to graze  ;; goat procedure

  if (energia_acquisita != food-max) or (other units-here = nobody)
  [
    let new-food-amt (energia_acquisita + get-amt-eaten );
    if (new-food-amt < food-max)
      [ set energia_acquisita new-food-amt ]
;       if (new-food-amt < food-max)
 ;     set energia_acquisita new-food-amt
     ; [ set energia_acquisita food-max ]
  ]

 rt (random-float 360)
 lt (random-float 360)
 fd 1

 if energia_acquisita <= 0 [ask farmers with [user-id = [owner#] of myself][set lost_cows lost_cows + 1] die]
end


;; returns amount of energia eaten at patch and
;; sets the patch energia amount accordingly
to-report get-amt-eaten  ;; goat procedure
  let reduced-amt (riserva-energetica - energia_richiesta)
  ifelse (reduced-amt <= 0)
  [
    set riserva-energetica 0
    report riserva-energetica
  ]
  [
    set riserva-energetica reduced-amt
    report energia_richiesta
  ]
end

;; collect milk and sells them at market ($1 = 1 gallon)
to profit-units  ;; farmer procedure ex milk-plants
  set guadagno_giornaliero
    (round-to-place (sum [energia_acquisita] of my-units) 10)
  ask my-units
    [ set energia_acquisita 0 ]
  set revenue-lst (lput guadagno_giornaliero revenue-lst)
  set capitale_totale capitale_totale + guadagno_giornaliero - (costo_gestione/unità * n_mucche_comprate_a_settimana) ; - costo/nuove_unità
;  set capitale_totale-lst (lput capitale_totale capitale_totale-lst)
  set numero_mucche count my-units
  set numero_mucche-lst (lput (count my-units) numero_mucche-lst)
  set lost_cows-lst (lput lost_cows lost_cows-lst)

  send-personal-info
  if capitale_totale <= 0 [
hubnet-send user-id "Messaggio per voi:" "Ci dispiace, siete fuori dal mercato :("
ask my-units [die]
    die]
end

;; the goat market setup
to invest_capital
  ask farmers
  [
    if n_mucche_comprate_a_settimana > count my-units
      [set units_to_buy (n_mucche_comprate_a_settimana - count my-units)
        buy-units units_to_buy ]; (n_mucche_comprate_a_settimana - count my-units) ]
   if n_mucche_comprate_a_settimana < count my-units
        [ set units_to_buy (count my-units - n_mucche_comprate_a_settimana)
            ask n-of units_to_buy my-units [die]] ; (count my-units - n_mucche_comprate_a_settimana) my-units [die]]
 ;       buy-units (n_mucche_comprate_a_settimana) ]
;    if n_mucche_comprate_a_settimana < 0
;      [ lose-units (- n_mucche_comprate_a_settimana / 7) ]
    set n_mucche-lst (lput n_mucche_comprate_a_settimana n_mucche-lst)
    set contrcom-lst (lput contributo_comune_rigenerazione contrcom-lst)
;    set guadagno_giornaliero 0
    send-personal-info
  ]
end

;; farmers buy units at market
to buy-units [ num-units-desired ]  ;; farmer procedure
  let got-number-desired? true
  let num-units-afford (int (capitale_totale / costo/nuove_unità))
  let num-units-purchase num-units-desired
  if (num-units-afford < num-units-purchase)
  [
    set num-units-purchase num-units-afford
    set got-number-desired? false
  ]
  let cost-of-purchase num-units-purchase * costo/nuove_unità
  set capitale_totale (capitale_totale - cost-of-purchase)
  set capitale_totale-lst (lput capitale_totale capitale_totale-lst)
  hatch num-units-purchase
    [ setup-units user-id ]
end

;; farmers eliminate some of their units (with no gain in assets)
;to lose-units [ num-to-lose ]  ;; farmer procedure
;  if ((count my-units) < num-to-lose)
;    [ set num-to-lose (count my-units) ]
;  ask (n-of num-to-lose my-units)
;    [ die ]
;end

;; initializes goat variables
to setup-units [ farmer# ]  ;; turtle procedure
  set breed units
  setxy random-xcor random-ycor
  set owner# farmer#
  if owner# = "azzurro" [set shape "cow" set color cyan set size 1.5]
  if owner# = "giallo" [set shape "cow" set color yellow set size 1.5]
  if owner# = "rosa" [set shape "cow" set color pink + 1 set size 1.5]
  if owner# = "rosso" [set shape "cow" set color red set size 1.5]
  if owner# = "blu" [set shape "cow" set color blue set size 1.5]
  set energia_acquisita 0
  set riserve_unità 0
  show-turtle
end

to contributo_comune_refill
ask farmers [
set capitale_totale capitale_totale - contributo_comune_rigenerazione
; hubnet-send user-id "Guadagno totale, Euro:" capitale_totale
;if capitale_totale <= 0 [died_farmers die]
;    send-personal-info
]

set refilling (sum [(contributo_comune_rigenerazione * 10)] of farmers  / count patches with [riserva-energetica < 50])
ask patches with [riserva-energetica < 50]
[
set riserva-energetica riserva-energetica + refilling
color-patches
if riserva-energetica >= 50 [set riserva-energetica 50]
]
plot-value "Risorse Ambientali" totale_riserva-energetica

end


;; updates patches' color and increase energia supply with growth rate
to reset-patches
  ask patches [
    let crisis_patches count patches with [riserva-energetica < energia-max]


  if (riserva-energetica < energia-max)
  [
        let new-energia-amt (riserva-energetica + rinnovo_energetico)
        ifelse (new-energia-amt > energia-max)
      [ set riserva-energetica energia-max ]
      [ set riserva-energetica new-energia-amt]
    color-patches
      ]
;    ]
 ]
end

;; colors patches according to amount of energia on the patch
to color-patches  ;; patch procedure
  set pcolor (scale-color green riserva-energetica -5 (2 * energia-max))
end


;;;;;;;;;;;;;;;;;;;;;;;;
;; Plotting Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;


to plot-value [ name-of-plot value ]
  set-current-plot name-of-plot
  plot value
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculation Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report totale_riserva-energetica
  report sum [ riserva-energetica ] of patches
end

to-report guadagno_medio
  report mean [ guadagno_giornaliero ] of farmers
end

;; returns agentset that of units of a particular farmer
to-report my-units  ;; farmer procedure
  report units with [ owner# = [user-id] of myself ]
end

;; rounds given number to certain decimal-place
to-report round-to-place [ num decimal-place ]
  report (round (num * decimal-place)) / decimal-place
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Code for interacting with the clients ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; determines which client sent a command, and what the command was
to listen-to-clients
  while [ hubnet-message-waiting? ]
  [
    hubnet-fetch-message
    ifelse hubnet-enter-message?
    [
      create-new-farmer hubnet-message-source
    ]
    [
      ifelse hubnet-exit-message?
        [ remove-farmer hubnet-message-source ]
        [ execute-command hubnet-message-tag ]
    ]
  ]
end

;; NetLogo knows what each student turtle is supposed to be
;; doing based on the tag sent by the node:
;; n_mucche_comprate_a_settimana - determine quantity of student's desired purchase
to execute-command [command]
  if command = "n_mucche_comprate_a_settimana"
  [
    ask farmers with [user-id = hubnet-message-source]
      [ set n_mucche_comprate_a_settimana hubnet-message ]
    stop
  ]

  if command = "contributo_comune_rigenerazione"
  [
    ask farmers with [user-id = hubnet-message-source]
      [ set contributo_comune_rigenerazione hubnet-message ]
    stop
  ]

end

to create-new-farmer [ id ]
  create-farmers 1
  [
    set user-id id
    setup-farm
    reset-farmers-vars
    hubnet-send id "n_mucche_comprate_a_settimana" n_mucche_comprate_a_settimana
    send-system-info
  ]
end

;; situates the farmer in particular location
to setup-farm  ;; farmer procedure
  setxy ((random-float (world-width - 2)) + min-pxcor + 1)
        ((random-float (world-height - 2)) + min-pycor + 1)
  hide-turtle
end

;; set farmer variables to initial values
to reset-farmers-vars  ;; farmer procedure
  ;; reset the farmer variable to initial values
  set revenue-lst []
  set capitale_totale-lst []
  ;set total-lst []
  set numero_mucche-lst []
  set contrcom-lst []
  set n_mucche-lst[]
  set lost_cows-lst []
  set n_mucche_comprate_a_settimana 1
  set contributo_comune_rigenerazione 0
  set capitale_totale costo/nuove_unità
  set guadagno_giornaliero 0
  set lost_cows 0
  ;; get rid of existing units
  ask my-units
    [ die ]

  ;; create new units for the farmer
  hatch unità_iniziali/gruppo
    [ setup-units user-id ]

  send-personal-info
end

;; sends the appropriate monitor information back to the client
to send-personal-info  ;; farmer procedure
  hubnet-send user-id "Voi allevate la mandria di colore:" user-id
  hubnet-send user-id "€ guadagno giornaliero" guadagno_giornaliero
  hubnet-send user-id "€ guadagno totale" capitale_totale
  hubnet-send user-id "€ costo nuove mucche" (costo/nuove_unità * new_cows)
  hubnet-send user-id "€ costo gestione mucche settimanale" ((costo_gestione/unità * n_mucche_comprate_a_settimana) * 7)
  hubnet-send user-id "€ costi totali a settimana" ((new_cows * costo/nuove_unità)  +  contributo_comune_rigenerazione + ((n_mucche_comprate_a_settimana * costo_gestione/unità) * 7))
;  hubnet-send user-id "€ costi totali a settimana" (((costo/nuove_unità * n_mucche_comprate_a_settimana))  +  contributo_comune_rigenerazione + ((costo_gestione/unità * n_mucche_comprate_a_settimana) * 7)) - 10
  hubnet-send user-id "nuove mucche da comprare" new_cows
  hubnet-send user-id "mucche in vita" count my-units
  hubnet-send user-id "mucche perse" lost_cows
 ; hubnet-send user-id "c.c.r." contributo_comune_rigenerazione
;  hubnet-send user-id "costo settimanale mucche" ((n_mucche_comprate_a_settimana * costo/nuove_unità))
;  hubnet-send user-id "costo contributo comune" contributo_comune_rigenerazione
;  hubnet-send user-id "totale mucche settimana" (n_mucche_comprate_a_settimana)
end

;; sends the appropriate monitor information back to one client
to send-system-info  ;; farmer procedure
  hubnet-send user-id "Giorno" giorno
  hubnet-send user-id "Settimana" settimana
end

;; broadcasts the appropriate monitor information back to all clients
to broadcast-system-info
;  hubnet-broadcast "€ costo gestione mucche" costo/nuove_unità
  hubnet-broadcast "Giorno" giorno
  hubnet-broadcast "Settimana" settimana
end

;; delete farmers once client has exited
to remove-farmer [ id ]
  let old-color 0
  ask farmers with [user-id = id]
  [
    set old-color color
    ask my-units
      [ die ]
    die
  ]

end

to write_csv


foreach ["rosso" "azzurro" "giallo" "rosa" "blu"]  [ x -> csv:to-file (word "data/" TURN x "_capital.csv") [capitale_totale-lst] of farmers with [user-id = x]]
  foreach ["rosso" "azzurro" "giallo" "rosa" "blu"]  [ x -> csv:to-file (word "data/" TURN x "_giornaliero.csv") [revenue-lst] of farmers with [user-id = x]]
  foreach ["rosso" "azzurro" "giallo" "rosa" "blu"]  [ x -> csv:to-file (word "data/" TURN x "_mucche.csv") [numero_mucche-lst] of farmers with [user-id = x]]
  foreach ["rosso" "azzurro" "giallo" "rosa" "blu"]  [ x -> csv:to-file (word "data/" TURN x "_muccheslider.csv") [n_mucche-lst] of farmers with [user-id = x]]
  foreach ["rosso" "azzurro" "giallo" "rosa" "blu"]  [ x -> csv:to-file (word "data/" TURN x "_ccr.csv") [contrcom-lst] of farmers with [user-id = x]]

end

to-report new_cows
  ifelse (n_mucche_comprate_a_settimana > count my-units)
  [report (n_mucche_comprate_a_settimana - count my-units)][report 0]
end

;to died_farmers
;hubnet-send user-id "Messaggio per voi:" "Ci dispiace, siete fuori dal mercato :("
;  hubnet-broadcast "Messaggio per voi:" "Ci dispiace, siete fuori dal mercato :("
;ask my-units [die]
;end

; Copyright 2002 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
492
10
1053
572
-1
-1
26.333333333333332
1
10
1
1
1
0
1
1
1
-10
10
-10
10
1
1
1
ticks
30.0

BUTTON
1119
245
1208
278
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
879
594
1007
627
unità_iniziali/gruppo
unità_iniziali/gruppo
0
1
1.0
1
1
unità
HORIZONTAL

SLIDER
477
594
602
627
costo/nuove_unità
costo/nuove_unità
1
2000
10.0
1
1
€
HORIZONTAL

SLIDER
743
595
870
628
ritmo_cicli
ritmo_cicli
2
50
11.0
1
1
NIL
HORIZONTAL

BUTTON
1122
162
1211
195
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
1157
112
1247
145
login
listen-to-clients
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
606
595
733
628
rinnovo_energetico
rinnovo_energetico
0
10
0.1
0.01
1
NIL
HORIZONTAL

PLOT
23
10
470
208
Capitale Totale
NIL
NIL
0.0
10.0
-10.0
400.0
true
true
"" ""
PENS
"azzurro" 1.0 0 -11221820 true "" "plot [capitale_totale] of one-of farmers with [user-id = \"azzurro\"]"
"giallo" 1.0 0 -1184463 true "" "plot [capitale_totale] of one-of farmers with [user-id = \"giallo\"]"
"rosa" 1.0 0 -1664597 true "" "plot [capitale_totale] of one-of farmers with [user-id = \"rosa\"]"
"rosso" 1.0 0 -2674135 true "" "plot [capitale_totale] of one-of farmers with [user-id = \"rosso\"]"
"blu" 1.0 0 -13345367 true "" "plot [capitale_totale] of one-of farmers with [user-id = \"blu\"]"

PLOT
1622
126
1844
316
Numero mucche perse
NIL
NIL
0.0
10.0
0.0
8.0
true
true
"" ""
PENS
"azzurro" 1.0 1 -11221820 true "" " ifelse (ticks mod ritmo_cicli) != 0\n []\n [plot (([n_mucche_comprate_a_settimana] of one-of farmers with [user-id = \"azzurro\"] / 7) - count units with [owner# = \"azzurro\"])]"
"giallo" 1.0 1 -1184463 true "" " ifelse (ticks mod ritmo_cicli) != 0\n []\n [plot (([n_mucche_comprate_a_settimana] of one-of farmers with [user-id = \"giallo\"] / 7) - count units with [owner# = \"giallo\"])]"
"rosa" 1.0 1 -1664597 true "" " ifelse (ticks mod ritmo_cicli) != 0\n []\n [plot (([n_mucche_comprate_a_settimana] of one-of farmers with [user-id = \"rosa\"] / 7) - count units with [owner# = \"rosa\"])]"
"rosso" 1.0 1 -2674135 true "" " ifelse (ticks mod ritmo_cicli) != 0\n []\n [plot (([n_mucche_comprate_a_settimana] of one-of farmers with [user-id = \"rosso\"] / 7) - count units with [owner# = \"rosso\"])]"
"blu" 1.0 1 -13345367 true "" " ifelse (ticks mod ritmo_cicli) != 0\n []\n [plot (([n_mucche_comprate_a_settimana] of one-of farmers with [user-id = \"blu\"] / 7) - count units with [owner# = \"blu\"])]"

BUTTON
1155
74
1246
107
show_costs
ask farmers [\nsend-personal-info\n\n]\n\n 
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1075
327
1132
372
azzurro
[contributo_comune_rigenerazione] of one-of farmers with [user-id = \"azzurro\"]
2
1
11

MONITOR
1075
376
1132
421
giallo
[contributo_comune_rigenerazione] of one-of farmers with [user-id = \"giallo\"]
2
1
11

MONITOR
1075
423
1132
468
rosa
[contributo_comune_rigenerazione] of one-of farmers with [user-id = \"rosa\"]
2
1
11

MONITOR
1075
469
1132
514
rosso
[contributo_comune_rigenerazione] of one-of farmers with [user-id = \"rosso\"]
2
1
11

MONITOR
1075
516
1132
561
blu
[contributo_comune_rigenerazione] of one-of farmers with [user-id = \"blu\"]
2
1
11

MONITOR
1153
10
1265
67
Settimana
settimana
17
1
14

TEXTBOX
1061
288
1148
316
Contributo comune singoli gruppi
10
0.0
1

PLOT
1629
332
1965
504
Risorse Ambientali 7 days
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"" 1.0 0 -14333415 true "" "ifelse (ticks mod ritmo_cicli) != 0 [] [plot totale_riserva-energetica]"

MONITOR
1655
458
1753
503
risorse ambientali
totale_riserva-energetica
2
1
11

PLOT
1634
131
2025
320
Report mucche perse 7 days
NIL
NIL
0.0
30.0
0.0
8.0
true
true
"" ""
PENS
"azzurro" 1.0 0 -11221820 true "" " ifelse (ticks mod ritmo_cicli) != 0\n []\n [plot [lost_cows] of one-of farmers with [user-id = \"azzurro\"]]"
"giallo" 1.0 0 -1184463 true "" "ifelse (ticks mod ritmo_cicli) != 0\n []\n [plot [lost_cows] of one-of farmers with [user-id = \"giallo\"]]"
"rosa" 1.0 0 -1664597 true "" "ifelse (ticks mod ritmo_cicli) != 0\n []\n [plot [lost_cows] of one-of farmers with [user-id = \"rosa\"]]"
"rosso" 1.0 0 -2674135 true "" "ifelse (ticks mod ritmo_cicli) != 0\n []\n [plot [lost_cows] of one-of farmers with [user-id = \"rosso\"]]"
"blu" 1.0 0 -13345367 true "" "ifelse (ticks mod ritmo_cicli) != 0\n []\n [plot [lost_cows] of one-of farmers with [user-id = \"blu\"]]"

MONITOR
1068
10
1149
67
Giorno
giorno
17
1
14

INPUTBOX
1071
75
1147
135
TURN
GE_12_
1
0
String

SLIDER
1012
593
1184
626
costo_gestione/unità
costo_gestione/unità
0
100
10.0
1
1
€
HORIZONTAL

BUTTON
1174
203
1262
236
choice
if giorno >= 7 [invest_capital]\n\nif giorno >= 14 [contributo_comune_refill]\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
1160
309
1363
563
10

BUTTON
1380
319
1443
352
rank
clear-output\noutput-print (word [user-id] of farmers [capitale_totale] of farmers)
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
22
212
471
402
Report mucche morte
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"azzurro" 1.0 0 -11221820 true "" "plot [lost_cows] of one-of farmers with [user-id = \"azzurro\"]"
"giallo" 1.0 0 -1184463 true "" "plot [lost_cows] of one-of farmers with [user-id = \"giallo\"]"
"rosa" 1.0 0 -1664597 true "" "plot [lost_cows] of one-of farmers with [user-id = \"rosa\"]"
"rosso" 1.0 0 -2674135 true "" "plot [lost_cows] of one-of farmers with [user-id = \"rosso\"]"
"blu" 1.0 0 -13345367 true "" "plot [lost_cows] of one-of farmers with [user-id = \"blu\"]"

PLOT
23
403
472
587
Risorse Ambientali
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot totale_riserva-energetica"

MONITOR
22
543
130
588
risorse ambientali
totale_riserva-energetica
2
1
11

BUTTON
1088
202
1171
235
max_buying
ask farmers [\nifelse n_mucche_comprate_a_settimana > int (capitale_totale / costo/nuove_unità)\n[hubnet-send user-id \"Messaggio per voi:\" (word \"Attenti! Con il vostro capitale potete comprare solo fino a \" int (capitale_totale / costo/nuove_unità) \" mucche!\")]\n[hubnet-send user-id \"Messaggio per voi:\" \"\"]\n]
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## Setting per laboratorio (vedi calculations)

costo/nuove_unità 10
rinnovo_energetico 0.1
ritmo_cicli 11
unità_inziali/gruppo 1

Tenere sempre premuto show_costs and login
SETUP
GO
quando scelto contributo comune >> rinnovo_risorse

## Calculations

* giorno = ticks mod ritmo_cicli, usa il remainder della divisione (mod): scatta quando ticks è multiplo di ritmo_cicli. All’interno di ogni giorno, si ripete l’assorbimento dell’energia_richiesta  da parte di ogni unità dalla riserva-energetica del patch (la cella nello spazio) dove si trova (patch-here). L’assorbimento continua e l’unità sopravvive intanto che riserva-energetica del patch-here > 0. Anche se l’unità muore, l’energia assorbita si somma per calcolare il guadagno_giornaliero del suo gruppo (farmer nel modello)

* energia_richiesta da ogni singola unità = (round (100 / (ritmo_cicli - 1))). Con ritmo_cicli = 11: 10 unità di energia_richiesta che viene sottratta alla riserva_energetica del patch dove si trova l’unità (patch-here)
Di default, riserva_energetica di ogni patch a tempo 0 = 50, con riserva-max =  50

* guadagno_giornaliero = (riserva_energetica patch-here - energia_richiesta dall’unità) + rinnovo_energetico (costante di rigenerazione del patch, altrimenti può solo esaursi), ripetuto all’interno del giono finchè riserva-energetica patch-here > 0. 
Con rinnovo_energetico = 0.1 e ritmo_cicli 11:
(50 - 10 + 0.1) = (40.1 - 10 + 0.1) [10 unità acquisite] = (30.2 - 10 + 0.1) [10 unità acquisite] = (20.3 - 10 + 0.1) [10 unità  acquisite] = (10.40 - 10 + 0.1)  [10 unità acquisite] = in 1 giorno si sottraggono 10 unità di energia_richiesta dal patch 4 volte, con un guadagno giornaliero uguale a 40.

* guadagno totale (capitale) = (guadagno giornaliero * 1) + ((guadagno giornaliero * units) * (day-1)) - ((costo_unità * units) * (day-1)) - (costo_unità * (units - 1)), perchè by default il modello originale impone che il primo giorno ci sia solo un'unità e il costo dell’unità del primo giorno è annullato (capitale = costo unità) per far bilanciare a zero e non iniziare con un debito.
Con capitale < 0, il gruppo muore

Con 1 unità e 7 giorni con ritmo_cicli 11 e rinnovo_energetico 0.1, costo unità 10:
(40 + ((40 * 1) * 6)) - ((1 * 10) * 6) - (10 * (1 - 1))) = 220
Con 4 unità e 7 giorni con ritmo_cicli 11 e rinnovo_energetico 0.1, costo unità 10:
(40 + ((40 * 4) * 6)) - ((4 * 10) * 6) - (10 * (4 - 1)) = 730

Da considerarsi che i calcoli di queste equazioni risentono delle dinamiche del modello per cui possono variare: le nuove unità si collocano random nello spazio, quindi influenzate dal consumo energetico delle altre unità. I valori calcolati sono alterati soprattutto quando:
- ci sono più unità e le nuove unità rischiano di cadere in una cella già esaurita
- sono passati più giorni, quindi ci possono essere più celle esaurite
- dato che le celle (patch) si rigenerano non allo stesso momento (dipendendo dalle unità che hanno attinto nel frattempo), il livello iniziale di riserva_energetica del patch da cui attingono nuove unità può essere diverso

Noi dobbiamo cercare di tenere quanto più controllo per avere risultati quanto più controllabili ai fini della discussione: qui con lo scenario proposto da usare nel gioco



## HOW TO CITE

Autor: Rocco Paolillo

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.


Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the HubNet software as:

* Wilensky, U. & Stroup, W. (1999). HubNet. http://ccl.northwestern.edu/netlogo/hubnet.html. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2002 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This activity and associated models and materials were created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

chicken
false
0
Circle -7500403 true true 62 92 178
Circle -7500403 true true 45 15 120
Polygon -7500403 true true 45 60 75 105 0 105
Polygon -7500403 true true 75 225 135 300 165 210 165 225 165 300 225 225 135 150 165 150 165 150 180 165

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

gameover
false
0
Circle -955883 true false 105 15 92
Circle -16777216 true false 120 30 30
Circle -16777216 true false 150 30 30
Polygon -2674135 true false 15 225 75 225 75 300 15 300 15 225 15 240 60 240 60 285 30 285
Polygon -2674135 true false 75 225 105 300 135 225 120 225 105 270 90 225 75 225
Polygon -2674135 true false 135 225 135 300 195 300 180 300 180 285 150 285 150 270 180 270 180 255 150 255 150 240 180 240 180 225 135 225
Polygon -2674135 true false 195 225 195 300 210 300 210 270 210 255 225 300 240 300 225 255 240 255 240 225 195 225 210 240 225 240 225 240 225 255 210 255
Polygon -2674135 true false 15 120 75 120 75 135 30 135 30 165 30 180 60 180 60 165 45 165 45 150 75 150 90 150 90 165 75 165 75 195 15 195
Polygon -2674135 true false 105 195 105 120 150 120 150 195 135 195 135 135 120 135 120 195 105 195
Polygon -2674135 true false 120 150 135 150 135 165 120 165
Polygon -2674135 true false 165 120 165 195 180 195 180 150 195 165 210 150 210 195 225 195 225 120 195 135
Polygon -2674135 true false 240 120 300 120 285 135 255 135 255 150 285 150 285 165 255 165 255 180 285 180 285 195 240 195
Circle -16777216 true false 270 285 0
Polygon -2674135 true false 255 210 255 270 270 270 270 210
Rectangle -2674135 true false 255 285 270 300

goat
false
0
Polygon -7500403 true true 97 116 125 128 166 130 209 119 243 136 244 171 231 188 215 193 215 243 205 244 203 192 169 182 131 185 130 245 116 245 115 184 87 138
Polygon -7500403 true true 243 146 260 152 259 180 253 155
Polygon -7500403 true true 97 113 82 93 61 93 34 134 43 145 59 137 79 133 86 138
Polygon -7500403 true true 58 136 65 150 55 161 58 146
Rectangle -7500403 true true 88 123 103 138
Rectangle -7500403 true true 88 120 100 133
Rectangle -7500403 true true 88 119 100 131
Rectangle -7500403 true true 86 119 95 123
Rectangle -7500403 true true 88 115 98 124
Rectangle -7500403 true true 87 134 90 140
Polygon -6459832 true false 69 91 76 65 114 57 120 68 109 64 83 71 80 93
Polygon -7500403 true true 203 193 201 242 204 243
Polygon -7500403 true true 205 217 201 242 205 242
Polygon -7500403 true true 105 168 81 186 90 223 101 222 94 188 118 183
Polygon -7500403 true true 184 186 173 197 186 223 196 213 183 196
Polygon -6459832 true false 68 92 82 92

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
need-to-manually-make-preview-for-this-model
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
493
10
956
459
0
0
0
1
1
1
1
1
0
1
1
1
-10
10
-10
10

MONITOR
210
91
345
140
€ guadagno giornaliero
NIL
3
1

MONITOR
178
295
319
344
€ costo nuove mucche
NIL
3
1

MONITOR
348
92
483
141
€ guadagno totale
NIL
3
1

SLIDER
27
244
283
277
n_mucche_comprate_a_settimana
n_mucche_comprate_a_settimana
1.0
100.0
0
1.0
1
NIL
HORIZONTAL

MONITOR
358
10
415
59
Giorno
NIL
3
1

SLIDER
22
425
478
458
contributo_comune_rigenerazione
contributo_comune_rigenerazione
0.0
1000.0
0
10.0
1
€
HORIZONTAL

MONITOR
32
11
222
60
Voi allevate la mandria di colore:
NIL
3
1

MONITOR
22
294
170
343
nuove mucche da comprare
NIL
3
1

MONITOR
24
172
478
221
€ costi totali a settimana
NIL
3
1

MONITOR
290
237
480
286
€ costo gestione mucche settimanale
NIL
3
1

TEXTBOX
27
149
475
167
Ricordate di non spendere più di quanto guadagnato (€ guadagno totale)!
13
0.0
1

MONITOR
418
10
480
59
Settimana
NIL
3
1

TEXTBOX
968
16
983
34
NIL
10
0.0
1

TEXTBOX
970
16
985
34
NIL
10
0.0
1

TEXTBOX
499
456
527
474
NIL
10
0.0
1

MONITOR
19
355
476
404
Messaggio per voi:
NIL
3
1

MONITOR
111
92
198
141
mucche perse
NIL
3
1

MONITOR
26
92
108
141
mucche in vita
NIL
3
1

@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
