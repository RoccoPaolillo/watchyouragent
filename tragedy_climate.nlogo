;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variable and Breed declarations ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals
[
  giorno                ;; number of days so far

;  colori             ;; list that holds the colors used for students' turtles
;  nomi-colori        ;; list that holds the names of the colors used for
                     ;; students' turtles
;  numero-colori         ;; number of colors in the color list
;  colori-usati        ;; list that holds the shape-color pairs that are
                     ;; already being used

  n/a                ;; unset variable indicator

  ;; quick start instructions variables
  quick-start        ;; current quickstart instruction displayed in the
                     ;; quickstart monitor
  qs-item            ;; index of the current quickstart instruction
  qs-items           ;; list of quickstart instructions

  energia-max          ;; energia capacity
  food-max           ;; energia collection capacity
  energia_richiesta          ;; amount of energia collected at each move
  refilling
 ; tax-paid
]

patches-own
[
 ; special-store
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
  compra_nuove_unità   ;; desired quantity of units to purchase
  revenue-lst        ;; list of each days' revenue collection
  capitale_totale       ;; total of past revenue, minus expenses
  guadagno_giornaliero    ;; the revenue collected at the end of the last day
  contributo_comune
  ; riserva_personale

]


;;;;;;;;;;;;;;;;;;;;;
;; Setup Functions ;;
;;;;;;;;;;;;;;;;;;;;;

to startup
  setup-quick-start
  hubnet-reset
  setup
end

;; initializes the display
;; but does not clear already created farmers
to setup
  ; hubnet-broadcast "Istruzioni" ""
  if any? turtles with [shape = "gameover"] [ask turtles with [shape = "gameover"][die]]
  setup-globals
  setup-patches
  clear-output
  clear-all-plots
  ask farmers
    [ reset-farmers-vars ]
;  hubnet-broadcast "Aspetta per la tua nuova mossa ..."
;    (word "Everyone starts with " unità_iniziali/gruppo " units.")
  hubnet-broadcast "compra_nuove_unità" 1
   hubnet-broadcast "contributo_comune" 0
;  hubnet-broadcast "riserva_personale" 0
  broadcast-system-info
end

;; initialize global variables
to setup-globals
  reset-ticks
  set giorno 0

  set energia-max 50
  set food-max 50
  ;; why this particular calculation?
  set energia_richiesta (round (100 / (ritmo_cicli - 1)))

;  set colori      [ white   gray   orange   brown    yellow    turquoise
;                    cyan    sky    blue     violet   magenta   pink ]
;  set nomi-colori ["white" "gray" "orange" "brown"  "yellow"  "turquoise"
;                   "cyan"  "sky"  "blue"   "violet" "magenta" "pink"]
;  set colori-usati []
;  set numero-colori length colori
  set n/a "n/a"
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
  ;  every .5
  ;   [ broadcast-system-info ]


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
      ask farmers
        [ profit-units ]
      invest_capital ;; toene buy units
      plot-graph
    ]

    reset-patches
  ]
  ; ask farmers [if not any? my-units [die]]
 if not any? units [create-turtles 1 [set shape "gameover" set size 20] stop ]
 ask farmers [if capitale_totale <= 0 [die]]
 broadcast-system-info
;  if giorno = 7 [stop]
end

;; goat move along the common looking for best patch of energia
to graze  ;; goat procedure

  if (energia_acquisita != food-max) or (other units-here = nobody)
  [
    let new-food-amt (energia_acquisita + get-amt-eaten );
    if (new-food-amt < food-max)
      [ set energia_acquisita new-food-amt ]
     ; [ set energia_acquisita food-max ]
  ]
; bloccare prossime tre linee se non si vogliono far muovere gli agenti
ifelse muovi_unità [
  rt (random-float 90)
  lt (random-float 90)
  fd 1
  ][]

;  ifelse is_crisi_energetica [
  ; set riserve_unità (energia_acquisita + [riserva_personale] of one-of farmers with [user-id = [owner#] of myself])
  ; ask patch-here [set ]
  ;   set riserve_unità [riserva_personale] of one-of farmers with [user-id = [owner#] of myself]
 ; ]
 ; [
 ;     set riserve_unità 0
 ; ]
   ; if riserve_unità = 0 [die]
  if energia_acquisita = 0 [die]
end


;; returns amount of energia eaten at patch and
;; sets the patch energia amount accordingly
to-report get-amt-eaten  ;; goat procedure
  let reduced-amt (riserva-energetica - (energia_richiesta * consumo_individuale))
  ifelse (reduced-amt < 0)
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
  set revenue-lst (fput guadagno_giornaliero revenue-lst)
  set capitale_totale capitale_totale + guadagno_giornaliero
  send-personal-info
end

;; the goat market setup
to invest_capital
  ask farmers
  [
    if compra_nuove_unità > 0
      [ buy-units compra_nuove_unità ]
    if compra_nuove_unità < 0
      [ lose-units (- compra_nuove_unità) ]
    if compra_nuove_unità = 0
      [ hubnet-send user-id "Aspetta per la tua nuova mossa ..." " " ]
    send-personal-info
    set capitale_totale (capitale_totale - contributo_comune ) ; - (riserva_personale * count my-units))
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
 ; hubnet-send user-id "Aspetta per la tua nuova mossa ..."
 ;   (seller-says got-number-desired? num-units-desired num-units-purchase)

  ;; create the units purchased by the farmer
  hatch num-units-purchase
    [ setup-units user-id ]
end

;; farmers eliminate some of their units (with no gain in assets)
to lose-units [ num-to-lose ]  ;; farmer procedure
  if ((count my-units) < num-to-lose)
    [ set num-to-lose (count my-units) ]
;  hubnet-send user-id "Aspetta per la tua nuova mossa ..."
;    (word "You lost " num-to-lose " units.")

  ;; eliminate the units ditched by the farmer
  ask (n-of num-to-lose my-units)
    [ die ]
end

;; reports the appropriate information on the transaction of purchasing units
to-report seller-says [ success? desired purchased ]
  let seller-message ""
  let cost purchased * costo/nuove_unità
  ifelse success?
  [
    ifelse (purchased > 1)
      [ set seller-message (word "Here are your " purchased " units.  ") ]
      [ set seller-message "Here is your unit.  " ]
    set seller-message (word seller-message "You have spent €" cost ".")
  ]
  [
    set seller-message (word "You do not have enough to buy " desired ".  "
      "You can afford " purchased " for €" cost ".")
  ]
  report seller-message
end

;; initializes goat variables
to setup-units [ farmer# ]  ;; turtle procedure
  set breed units
  setxy random-xcor random-ycor
  set owner# farmer#
  if owner# = "plant" [set shape "plant" set color cyan]
  if owner# = "car" [set shape "car" set color violet]
  if owner# = "cow" [set shape "cow" set color brown]
  if owner# = "house" [set shape "house" set color red]
  if owner# = "chicken" [set shape "chicken" set color blue]
  set energia_acquisita 0
  set riserve_unità 0
  show-turtle
end

;; updates patches' color and increase energia supply with growth rate
to reset-patches
  ask patches [
    let crisis_patches count patches with [riserva-energetica < energia-max]
    ifelse is_crisi_energetica
    [
    set riserva-energetica (riserva-energetica - crisi_energetica)
      if (riserva-energetica < energia-max)
      [
      ifelse any? units-here [
        let new-energia-amt (riserva-energetica + rinnovo_energetico + (energia-growth-rate_emergency / crisis_patches) + sum [riserve_unità] of units-here)
        ifelse (new-energia-amt > energia-max)
      [ set riserva-energetica energia-max ]
      [ set riserva-energetica new-energia-amt]
        ]
        [
        let new-energia-amt (riserva-energetica + rinnovo_energetico + (energia-growth-rate_emergency / crisis_patches))
        ifelse (new-energia-amt > energia-max)
      [ set riserva-energetica energia-max ]
      [ set riserva-energetica new-energia-amt]
        ]

    color-patches
      ]
    ]

    [
    set riserva-energetica (riserva-energetica)

  if (riserva-energetica < energia-max)
  [
        let new-energia-amt (riserva-energetica + rinnovo_energetico)
        ifelse (new-energia-amt > energia-max)
      [ set riserva-energetica energia-max ]
      [ set riserva-energetica new-energia-amt]
    color-patches
      ]
    ]
 ]
end

;; colors patches according to amount of energia on the patch
to color-patches  ;; patch procedure
  set pcolor (scale-color green riserva-energetica -5 (2 * energia-max))
end


;;;;;;;;;;;;;;;;;;;;;;;;
;; Plotting Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; plots the graph of the system
to plot-graph
  plot-value "Guadagno medio" guadagno_medio
end

;; plot value on the plot called name-of-plot
to plot-value [ name-of-plot value ]
  set-current-plot name-of-plot
  plot value
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Calculation Functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report totale_guadagno_giornaliero
  report sum [ guadagno_giornaliero ] of farmers
end

to-report totale_riserva-energetica
  report sum [ riserva-energetica ] of patches
end

to-report energia-growth-rate_emergency
  report sum [contributo_comune] of farmers
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

to-report consumo_individuale

  if owner# = "plant" [report 1]
  if owner# = "car" [report 1]
  if owner# = "cow" [report 1]
  if owner# = "house" [report 1]
  if owner# = "chicken" [report 1]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Quick Start functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; instructions to quickly setup the model, and clients to run this activity
to setup-quick-start
  set qs-item 0
  set qs-items
  [
    "Teacher: Follow these directions to run the HubNet activity."
      "Optional: Zoom In (see Tools in the Menu Bar)"
      "Optional: Change any of the settings...."
      "If you do change the settings, press the SETUP button."
      "Press the LOGIN button to allow people to login."
      "Everyone: Open up a HubNet Client on your machine and..."
        "type your user name, select this activity and press ENTER."

    "Teacher: Once everyone has logged in,..."
        "turn off the LOGIN button by pressing it again."
      "Have the students acquaint themselves with the information..."
        "available to them in the monitors, buttons, and sliders."
      "Then press the GO button to start the simulation."
      "Please note that you may adjust the length of time..."
        "GRAZING-PERIOD, that units are allowed to graze each day."
      "For a quicker demonstration, reduce the..."
        "GRASS-GROWTH-RATE slider."
      "To curb buying incentives of the students, increase..."
        "the COSTO/ITEM slider."
      "Any of the above mentioned parameters - ..."
        "GRAZING-PERIOD, GRASS-GROWTH-RATE, and COSTO/ITEM -..."
        "may be altered without stopping the simulation."

    "Teacher: To run the activity again with the same group,..."
        "stop the model by pressing the GO button, if it is on."
        "Change any of the settings that you would like."
      "Press the SETUP button."

    "Teacher: Restart the simulation by pressing the GO button again."

    "Teacher: To start the simulation over with a new group,..."
        "stop the model by pressing the GO button if it is on..."
        "press the RESET button in the Control Center"
        "and follow these instructions again from the beginning."
  ]
  set quick-start (item qs-item qs-items)
end

;; view the next item in the quickstart monitor
to view-next
  set qs-item qs-item + 1
  if qs-item >= length qs-items
    [ set qs-item length qs-items - 1 ]
  set quick-start (item qs-item qs-items)
end

;; view the previous item in the quickstart monitor
to view-prev
  set qs-item qs-item - 1
  if qs-item < 0
    [ set qs-item 0 ]
  set quick-start (item qs-item qs-items)
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
;; compra_nuove_unità - determine quantity of student's desired purchase
to execute-command [command]
  if command = "compra_nuove_unità"
  [
    ask farmers with [user-id = hubnet-message-source]
      [ set compra_nuove_unità hubnet-message ]
    stop
  ]

  if command = "contributo_comune"
  [
    ask farmers with [user-id = hubnet-message-source]
      [ set contributo_comune hubnet-message ]
    stop
  ]

 ;  if command = "riserva_personale"
  ; [
 ;    ask farmers with [user-id = hubnet-message-source]
 ;      [ set riserva_personale hubnet-message ]
   ;  stop
 ;  ]
end

to create-new-farmer [ id ]
  create-farmers 1
  [
    set user-id id
    setup-farm
  ;  set-unique-color
    reset-farmers-vars
    hubnet-send id "compra_nuove_unità" compra_nuove_unità
    send-system-info
  ]
end

;; situates the farmer in particular location
to setup-farm  ;; farmer procedure
  setxy ((random-float (world-width - 2)) + min-pxcor + 1)
        ((random-float (world-height - 2)) + min-pycor + 1)
  hide-turtle
end

;; pick a color for the turtle ;; RP we don't need anymore
; to set-unique-color  ;; turtle procedure
;  let code random numero-colori
; while [member? code colori-usati and count farmers < numero-colori]
;   [ set code random numero-colori ]
;  set colori-usati (lput code colori-usati)
;  set color item code colori

;end

;; set farmer variables to initial values
to reset-farmers-vars  ;; farmer procedure
  ;; reset the farmer variable to initial values
  set revenue-lst []
  set compra_nuove_unità 1
  set contributo_comune 0
  ;   set riserva_personale 0
  set capitale_totale costo/nuove_unità
  set guadagno_giornaliero 0

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
 ; hubnet-send user-id "My unit Color" (color->string color)
  hubnet-send user-id "Voi siete il gruppo:" user-id
  hubnet-send user-id "Guadagno giornaliero" guadagno_giornaliero
  hubnet-send user-id "Guadagno totale, Euro:" capitale_totale
;  hubnet-send user-id "My unit Population" count my-units
end

;; returns string version of color name
;to-report color->string [ color-value ]
;  report item (position color-value colori) nomi-colori
;end

;; sends the appropriate monitor information back to one client
to send-system-info  ;; farmer procedure
 ; hubnet-send user-id "Total guadagno_giornaliero" totale_guadagno_giornaliero
 ; hubnet-send user-id "Grass Amt" totale_riserva-energetica
  hubnet-send user-id "Costo nuove unità, Euro:" costo/nuove_unità
  hubnet-send user-id "Giorno" giorno
end

;; broadcasts the appropriate monitor information back to all clients
to broadcast-system-info
;  hubnet-broadcast "Total guadagno_giornaliero" totale_guadagno_giornaliero
;  hubnet-broadcast "Grass Amt" (int totale_riserva-energetica)
;  hubnet-broadcast "Istruzioni" round (((count patches * 50) - totale_riserva-energetica) / 5)
  hubnet-broadcast "Costo nuove unità, Euro:" costo/nuove_unità
  hubnet-broadcast "Giorno" giorno
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
;  if not any? farmers with [color = old-color]
;    [ set colori-usati remove (position old-color colori) colori-usati ]
end

; Copyright 2002 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
476
33
921
479
-1
-1
20.81
1
10
1
1
1
0
0
0
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
248
10
341
43
NIL
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
13
96
187
129
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
198
61
373
94
costo/nuove_unità
costo/nuove_unità
1
2000
10.0
1
1
€
HORIZONTAL

MONITOR
1308
230
1406
275
Avg-Revenue
guadagno_medio
1
1
11

PLOT
1305
52
1520
220
Guadagno medio
Day
Revenue
0.0
20.0
0.0
1000.0
true
false
"" ""
PENS
"" 1.0 0 -16777216 true "" ""

MONITOR
1309
297
1444
342
Guadagno attuale (all)
totale_guadagno_giornaliero
0
1
11

SLIDER
14
58
187
91
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
145
10
243
43
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

MONITOR
359
10
422
55
Giorno
giorno
3
1
11

BUTTON
1291
10
1409
43
Reset Instructions
setup-quick-start
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
1493
10
1577
43
NEXT >>>
view-next
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
1415
10
1493
43
<<< PREV
view-prev
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1311
353
1731
398
Quick Start Instructions- More in Info Window
quick-start
0
1
11

BUTTON
38
12
142
45
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
1533
207
1670
240
crisi_energetica
crisi_energetica
0
5
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
199
97
374
130
rinnovo_energetico
rinnovo_energetico
0
10
0.1
0.1
1
NIL
HORIZONTAL

PLOT
6
157
235
307
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
"car" 1.0 0 -8630108 true "" "plot [capitale_totale] of one-of farmers with [user-id = \"car\"]"
"cow" 1.0 0 -6459832 true "" "plot [capitale_totale] of one-of farmers with [user-id = \"cow\"]"
"house" 1.0 0 -2674135 true "" "plot [capitale_totale] of one-of farmers with [user-id = \"house\"]"
"plant" 1.0 0 -11221820 true "" "plot [capitale_totale] of one-of farmers with [user-id = \"plant\"]"
"chicken" 1.0 0 -13345367 true "" "plot [capitale_totale] of one-of farmers with [user-id = \"chicken\"]"

PLOT
244
157
471
307
Unità
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
"car" 1.0 0 -8630108 true "" "plot count units with [owner# = \"car\"]"
"cow" 1.0 0 -6459832 true "" "plot count units with [owner# = \"cow\"]"
"house" 1.0 0 -2674135 true "" "plot count units with [owner# = \"house\"]"
"plant" 1.0 0 -11221820 true "" "plot count units with [owner# = \"plant\"]"
"chicken" 1.0 0 -13345367 true "" "plot count units with [owner# = \"chicken\"]"

SWITCH
1533
170
1671
203
is_crisi_energetica
is_crisi_energetica
1
1
-1000

SWITCH
1438
251
1563
284
muovi_unità
muovi_unità
1
1
-1000

BUTTON
1550
133
1653
166
crisi_once
ask patches [set riserva-energetica riserva-energetica - 20]
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
989
360
1078
393
rinnovo_risorse
ask farmers [\nset capitale_totale capitale_totale - contributo_comune\nhubnet-send user-id \"Guadagno totale, Euro:\" capitale_totale\n]\n\nset refilling (sum [contributo_comune] of farmers / count patches with [riserva-energetica < 50])\nask patches with [riserva-energetica < 50]\n[\nset riserva-energetica riserva-energetica + refilling\ncolor-patches\nif riserva-energetica >= 50 [set riserva-energetica 50]\n]\nplot-value \"Risorse Ambientali\" totale_riserva-energetica\n\nhubnet-broadcast \"Istruzioni\" (word \"Energia ricevuta da ogni cella dal contributo comune: \" round refilling \" unità\")\n\n;write \"Energia ricevuta da ogni cella dal contributo comune: \" print refilling\n
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
19
309
279
459
Risorse Ambientali
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
"Risorse totali " 1.0 0 -16777216 true "" "plot totale_riserva-energetica"

BUTTON
930
161
1019
194
step: nuove unità
 hubnet-broadcast \"Istruzioni\" \"Ora che avete capito il gioco, potete decidere se comprare nuove unità\"
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
952
15
1083
48
cleanup-istructions
 hubnet-broadcast \"Istruzioni\" \"\"
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
929
54
1006
87
step: explore
 hubnet-broadcast \"Istruzioni\" \"Benvenuti! Prima vediamo come funziona il gioco!\"\n 
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
927
238
1048
271
step: environment crisis
 hubnet-broadcast \"Istruzioni\" \"OK, ma stiamo consumando le risorse dell'ambiente! Vogliamo riparare?\"
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
1052
239
1181
272
step: contributo comune
 hubnet-broadcast \"Istruzioni\" \"Potete decidere se investire a vostre spese con contributo_comune, quanto o niente\"
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
1018
275
1173
308
step: contributo comune calc
 hubnet-broadcast \"Istruzioni\" (word \"Potremmo salvare l'ambiente se ogni gruppo investisse \"  round (((count patches * 50) - totale_riserva-energetica) / 5)\" Euro , a voi la scelta!\")
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
312
325
420
370
risorse ambientali
totale_riserva-energetica
2
1
11

BUTTON
1053
160
1140
193
come comprare
 hubnet-broadcast \"Istruzioni\" \"Per comprare: compra_nuove_unità, con relativo costo. Potete decidere ora!\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
951
360
985
385
>>
20
0.0
1

TEXTBOX
1085
362
1128
387
<<
20
0.0
1

BUTTON
1023
98
1115
131
explore: capital
 hubnet-broadcast \"Istruzioni\" \"... a fine giornata, il vostro guadagno totale viene calcolato\"\n 
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
1011
54
1132
87
instruction: energy cons
 hubnet-broadcast \"Istruzioni\" \"Le unità del vostro gruppo sopravvivono assumendo risorse dal territorio dove sono...\"\n 
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
931
97
1017
130
energy: money
 hubnet-broadcast \"Istruzioni\" \"... le risorse consumate si trasformano nel vostro guadagno...\"\n 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
939
139
1089
157
show run stop 7
10
0.0
1

TEXTBOX
946
208
1043
226
decide, go, stop 7
10
0.0
1

TEXTBOX
973
333
1123
351
decide, go, stop 14
10
0.0
1

BUTTON
936
276
1007
309
division
 hubnet-broadcast \"Istruzioni\" \"I singoli contributi comuni sono sommati e divisi tra i territori esauriti\" 
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## Calculations and strategy

* giorno = ticks mod ritmo_cicli, scatta quando ticks è multiplo di ritmo_cicli, ogni tick in un giorno, stando le condizioni sottostanti, permette il calcolo di guadagno_giornaliero
* energia_richiesta = (round (100 / (ritmo_cicli - 1))). Con ritmo_cicli = 11: 10, sottratta alla riserva_energetica del patch, at time 0 = 50
* guadagno_giornaliero = riserva_energetica patch-here - energia_richiesta + rinnovo_energetico. Con rinnovo_energetico = 0.1 e ritmo_cicli 11:
(50 - 10 + 1) = (40.1 - 10 + 0.1) = (30.2 - 10 + 0.1) = (20.3 - 10 + 0.1) = (10.40 - 10 + 0.1) = sono 4 ticks in cui sottrae 10 unità = guadagno giornaliero 40
* guadagno totale = (guadagno giornaliero * 1) + ((guadagno giornaliero * units) * (day-1)) - ((costo_unità * units) * (day-1)) - (costo_unità * (units - 1)), perchè il primo giorno c'è solo un'unità e il costo è annullato (capitale = costo unità) by default.

Con 1 unità e 7 giorni con ritmo_cicli 11 e rinnovo_energetico 0.1, costo unità 10:
(40 + ((40 * 1) * 6)) - ((1 * 10) * 6) - (10 * (1 - 1))) = 220
Con 4 unità e 7 giorni con ritmo_cicli 11 e rinnovo_energetico 0.1, costo unità 10:
(40 + ((40 * 4) * 6)) - ((4 * 10) * 6) - (10 * (4 - 1)) = 730

Da considerarsi che le nuove unità si collocano random nello spazio, quindi influenzate dal consumo delle altre. I valori calcolati possono alterarsi quando:
- ci sono più unità e le nuove unità rischiano di cadere in una cella già esaurita
- sono passati più giorni, quindi ci possono essere più celle esaurite
- allo stesso modo, essendo passati più giorni le celle si rigenerano per via di rinnovo_energetico, con diversi livelli energetici da cui l'unità attinge

Per avere maggior controllo suggerisco il set: ritmo_ciclo 11 (40 guadagno giornaliero), bloccando a 7 giorni, massimo dare la possibilità di comprare 4 nuove unità. Testando con solo un attore. Tutto dipende da altri attori.

Suggerisco di lasciare consumo_energetico uguale per tutti i gruppi: se un gruppo consuma meno, di fatto ha più chance di aumentare il capitale, perchè ottiene più energia nel tempo e si riproduce più velocemente, con effetto del tempo, è più complicato (vedi slides HubNet).

Qui suggerisco una strategia più semplice, senza sliders continui, con il contributo comune una tantum da dividersi tra le celle con energia < 50 e più semplice. Cambiata anche la grafica con istruzioni per gli studenti. Il contributo quale spesa è sottratto dal capitale.


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
460
10
875
425
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
95
129
221
178
Guadagno giornaliero
NIL
3
1

MONITOR
243
205
386
254
Costo nuove unità, Euro:
NIL
3
1

MONITOR
230
129
365
178
Guadagno totale, Euro:
NIL
3
1

SLIDER
33
213
233
246
compra_nuove_unità
compra_nuove_unità
0.0
4.0
0
1.0
1
NIL
HORIZONTAL

MONITOR
380
10
437
59
Giorno
NIL
3
1

MONITOR
6
77
454
126
Istruzioni
NIL
3
1

SLIDER
34
294
249
327
contributo_comune
contributo_comune
0.0
400.0
0
1.0
1
NIL
HORIZONTAL

MONITOR
8
10
120
59
Voi siete il gruppo:
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
