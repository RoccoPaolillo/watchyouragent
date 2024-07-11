## DESCRIZIONE

Adattamento della tragedia dei beni comuni per uno scenario di cooperazione/competizione in sostenibilità ambientale. Ogni gruppo al proprio computer (farmer) rappresenta un settore economico/sociale che si nutre di energia e compete per sopravvivere. I gruppi sono:

plant = agricoltura\
house = edilizia\
car = automotiv\
cow = allevamento bovino\
chicken = allevamento pollame

I gruppi vivono nello spazio comune e le loro unità (con la forma del loro nome) prendono energia dalla cella in cui si trovano, mentre si espandono nel mondo. Quindi l'energia utilizzabile è un bene comune che può esaurirsi. Una costante di rinnovo energetica è introdotta per assicurarsi che l'energia non si consumi immediatamente. Il totale dell'energia comune consumata dipende da quanto consumano le unità dei diversi gruppi.
Il guadagno giornaliero di ogni gruppo è calcolato alla fine di ogni singolo giorno, e consiste nel totale dell'energia immagazzinata dalle singola unità di quel gruppo. Il capitale totale è l'insieme dei guadagni giornalieri sommati. 

Ogni gruppo può decidere se comprare nuove unità del proprio gruppo, ad un costo imposto per ogni unità, o investire in un *contributo_comune_emergenza* o in una *riserva_personale* per ognuna delle sue unità. Il costo di questi tre elementi è sottratto a fine giornata dal capitale totale. 

Il modeller può attivare esternamente una crisi_energetica che sottrae un totale deciso dal modeller dalla riserva_energetica di ogni singola cella. In caso di crisi energetica, l'effetto di riserva_personale e contributo_comune_emergenza si attivano. Riserva_personale aggiunge la riserva_personale investita dal gruppo all'energia archiviata da ogni singola unità, cossichè l'unità sopravvivere artificialmente. Per il contributo_comune_emergenza, l'investimento di ogni singolo gruppo viene sommato, e si aggiunge alla capacità di rinnovo energetico di ogni cella, rinforzando quindi le risorse comuni.

## PARAMETRI, CONDIZIONI, MONITORS

Globali: solo il modeller al nodo centrale può visualizzarli e manipolarli

* muovi_unità: per lasciar le unità muoversi e cercare nuova energia sul territorio, consigliato
* rinnovo_energetico: il totale di energia rinnovata naturalmente, senza interventi esterni, per ogni cella ad ogni decimo di secondo (every 0.1)
* is_crisi_energetica: attiva la crisi energetica se on
* crisi_energetica: il totale di risorse energetiche sottratte dalle risorse comuni ad ogni decimo di secondo (every 0.1)
* ritmo_cicli: quanti steps compongono un giorno (significando quanta energia è raccolta, quante nuove unità ci saranno in meno o più tempo o velocità di costi/guadagni)
* unità_iniziali/gruppo: con quante unità ogni gruppo inizia (di fatto non c'è costo per le unità iniziali, sono date probono)
* costi/nuove_unità: il costo per ogni unità comprate a partire dal giorno  1

Locali: appaiono solo al gruppo sul loro monitor e loro possono modificarli per il proprio gruppo (sono indipendenti dalle scelte degli altri gruppi):

* compra_nuove_unità: nuove unità che si vogliono comprare dal giorno 1
* contributo_comune_emergenza: quanto si vuole investire sulle risorse comuni da attivarsi in caso di crisi energetica. Rappresenta 
* riserva_personale: quanto si vuole investire sulle risorse per ogni singola unità del proprio gruppo in caso di crisi energetica
* Guadagno giornaliero: il totale dell'energia delle unità del proprio gruppo a fine giornata
* Capitale totale: il proprio capitale accumulatosi nel tempo (consiste di guadagni e costi sottratti)

## COMPUTAZIONI (semplificato citando gli steps dove avvengono)

* [energia disponibile per ogni singola cella (reset-patches)](https://github.com/RoccoPaolillo/tragedyclimate/blob/960cc0641d421343a1ebe9e7df625c3034d48ac1/tragedy_climate.nlogo#L289-L317)

* [guadagno dalle proprie unità (profit units) ](https://github.com/RoccoPaolillo/tragedyclimate/blob/960cc0641d421343a1ebe9e7df625c3034d48ac1/tragedy_climate.nlogo#L198-L206)

* [investimento del capitale (invest_capital)](https://github.com/RoccoPaolillo/tragedyclimate/blob/960cc0641d421343a1ebe9e7df625c3034d48ac1/tragedy_climate.nlogo#L209-L221)

* [acquisizione energia (graze)](https://github.com/RoccoPaolillo/tragedyclimate/blob/fc333669a83c8f98889848c1668658340261c668/tragedy_climate.nlogo#L156-L179)

## TRADUZIONI dei parametri

drought > crisi_energetica
cost/plant > costo/item
grass-growth-rate > rinnovo_energetico
sustainable-tax > contributo_emergenza
harvest-period > ritmo_cicli: marks end of the day
init-num-plants/farmer > unità_iniziali/gruppo
bite-size > energia richiesta
energy-supply > riserva-energetica
current-revenue > guadagno_attuale (fine del ciclo)
food-stored > energia_acquisita
bite-size > energia_richiesta
