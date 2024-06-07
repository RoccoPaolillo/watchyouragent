Model Description, adapted from Tragedy of the common:

* General scenario: agriculture, goats are now plants that feed on grass (soil) in the geographic area of each group (see below), if they have no grass in their spot, they die
* Each spot where a plant can be calculated hold grass that is consumed as long a plant is cultivated there
* Differently from the original Tragedy of the common, the amount of grass of each spot is made up of
```
* a stored-grass that is unique to each geographic area + dynamic grass-growth-rate that is the same by all geographic areas and that depends on a ```sustainble-tax``` each geographic area can choose to pay for or not
```

* Agents are each group of student (node in the network): they geographic areas NW, NE, SE, SW

* Resources:
  + unqueal for each group (grass-stored): each geographic area (one group) has an initial reservation of grass-stored their cultivation can count on
  + shared (grass-growth-rate): the speed to how much soil regenerates, it is shared equally by all geographic area
 
* Scenario (cost mechanisms to check, but it is the same as Tragedy of common):
  + every country has an initial ```init-num-plants\farmer``` which is the same for all
  + after every ```harvest-period```, every geographic area makes profit of their agriculture: the more plants they based, the more profit they have that can spend
  + They can spend to reinvest in more plants in their area at ```cost\plant```
  + They can also spend for a ```sustainable-tax``` that affects how much the renew of the shared grass-growth-rate will be (see below). This is the common resource

* In the front-end of each individual group (a geographic area):
  + they have an initial unequal amount of stored grass to count on
  + competition: how much plants they want to buy ```num-plants-to-buy```
  
    
* Dynamics scenario:
  + Groups must decide on a scenario of common limited resources, e.g. water to clean up
  + Each group must pay a fee to purify water choosing the amount to invest (e.g. 10 50 100)
  + Return of investment based on the fee
