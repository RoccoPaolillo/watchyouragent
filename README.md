## WHAT IS IT?

Adattamento della tragedia dei beni comuni. Ogni gruppo al proprio computer (farmer) rappresenta un settore economico/sociale che si nutre di energia e compete per sopravvivere. I gruppi sono:

plant = agricoltura
house = edilizia
car = automotiv
cow = allevamento bovino
chicken = allevamento pollame

I gruppi vivono nello spazio comune e le loro unità rappresentate dagli oggetti nella simulazione che richiamano il loro nome e proprio colore prendono energia dalla cella in cui si trovano, mentre vagano nel mondo. Quindi l'energia utilizzabile è un bene comune che può esaurirsi. Una costante di rinnovo energia esiste per assicurarsi che l'energia non si consumi immediatamente. Il totale dell'energia comune consumata dipende da quanto consumano le unità dei diversi gruppi e da quante ce ne sono.
Il guadagno giornaliero di ogni gruppo è calcolato a fine di ogni singolo giorno, e consiste nel totale dell'energia immagazzinata dalle singola unità di quel gruppo. Il capitale totale è l'insieme dei guadagni giornalieri sommati. 

Ogni gruppo può decidere se comprare nuove unità del proprio gruppo, ad un costo imposto per ogni unità, o investire in un contributo_comune_emergenza o in una riserva_personale moltiplicata per ogni unità del proprio gruppo sopravvissuta al momento. Il costo di questi tre elementi è sottratto a fine giornata dal capitale totale. 

Il modeller può attivare esternamente una crisi_energetica che sottrae un totale deciso dal modeller dalla riserva_energetica di ogni singola cella (il massimo è energia-max: 50). In caso di crisi energetica, l'effetto di riserva_personale e contributo_comune_emergenza si attivano. Riserva_personale aggiunge il totale di riserva_personale investito dal gruppo all'energia archiviata da ogni singola unità, perchè non sia uguale a zero, così che l'unità può sopravvivere artificialmente. Per il contributo_comune_emergenza, l'investimento di ogni singolo gruppo viene sommato, e si aggiunge alla capacità di rinnovo energetico di ogni cella, rinforzando quindi le risorse comuni.

## PARAMETRI, CONDIZIONI, MONITORS

Globali: solo il modeller al nodo centrale può visualizzarli e manipolarli

* muovi_unità: per lasciar le unità muoversi e cercare nuova energia sul territorio, consigliato
* rinnovo_energetico: il totale di energia rinnovata naturalmente, senza interventi esterni, per ogni cella, ogni decimo di secondo (every 0.1)
* is_crisi_energetica: attiva la crisi energetica se su on
* crisi_energetica: il totale di risorse energetiche sottratte dalle risorse comuni ad ogni decimo di secondo (every 0.1)
* ritmo_cicli: quanti steps compongono un giorno (significando quanta energia è raccolta, quante nuove unità ci saranno in meno o più tempo o velocità di costi/guadagni)
* unità_iniziali/gruppo: con quante unità ogni gruppo inizia (di fatto  non c'è costo per questi)
* costi/nuove_unità: il costo per ogni unità successive al giorno 1

Locali: appaiono solo al gruppo sul loro monitor e loro possono modificarli per il proprio gruppo (sono indipendenti dalle scelte degli altri gruppi):

* compra_nuove_unità: nuove unità che si vogliono comprare dal giorno 1
* contributo_comune_emergenza: quanto si vuole investire sulle risorse comuni da attivarsi in caso di crisi energetica. Rappresenta 
* riserva_personale: quanto si vuole investire sulle risorse per ogni singola unità del proprio gruppo in caso di crisi energetica
* Guadagno giornaliero: il totale dell'energia delle unità del proprio gruppo sopravvissute
* Capitale totale: il proprio capitale accumulatosi nel tempo (consiste di guadagni e costi sottratti)

## COMPUTAZIONI (semplificato citando gli steps dove avvengono)

* reset-patches (energia disponibile in ogni singola cella):
riserva-energeticsa iniziale = 50
new-energia-amt = (riserva-energetica + rinnovo_energetico)
energia-growth-rate_emergency = somma [contributo_comune_emergenza] di tutti i gruppi
se is_crisi_energetica attivato:
riserva-energetica (riserva-energetica - crisi_energetica)
new-energia-amt = riserva-energetica + rinnovo_energetico + energia-growth-rate_emergency

*  profit-units (guadagno dalle proprie unità per ogni gruppo
my-units: unità di quel gruppo
guadagno_giornaliero: (sum of [energia_acquisita] of my-units)
capitale_totale: capitale_totale + guadagno_giornaliero
capitale_totale per ogni singolo gruppo: capitale_totale + guadagno_giornaliero

* invest_capital (investimento del capitale guadagnato per ogni gruppo):
capitale_totale = capitale_totale - contributo_comune_emergenza - (riserva_personale * count my-units)


* graze (accumulo energia per unità di ogni gruppo)
energia_acquisita = ( riserva-energetica della cella - (energia_richiesta * consumo_individuale)), report get-amt-eaten
se is_crisi_energetica attivato: riserve_unità (energia_acquisita + [riserva_personale] del mio gruppo (farmer)
