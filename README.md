Model Description, adapted from Tragedy of the common:

* General scenario: agriculture, goats are now plants that feed on grass (soil) in 4 geographic area representing each group (see below), if they have no grass in their spot, they die
* Each spot where a plant can be cultivated holds grass that is consumed as long the plant is cultivated there
* Differently from the original Tragedy of the common, the amount of grass of each spot is made up of
```
* grass of each spot: stored-grass (unique to each geographic area) + dynamic grass-growth-rate (shared by all geographic area depends on the ```sustainable tax``` that geographic areas are willing to pay or not)
```

This is the main difference with the original Tragedy of the common model:
  + in the original model each spot had the same initial amount of grass-stored, now it is unequally distributed by geographic areas (or else, input by modeler)
  + grass-growth-rate, i.e. equivalent to renewable speed of resources, now depends on how much the geographic areas want to pay. Even if only one geographic area pays, everyone will benefit from the investment, proportional to the ```sustainable-tax``` paid. Taking 2 as the max grass-growth-rate speed in the original model, each geographic area can spend up to 0.25: if everyone pays, there is max renew for everyone (2*0,5); if no one pays the tax, there is no renew for everyone, they can count only on their grass-stored  (that will expire  eventually); if one pays 0.01, the renew is equivalent to 0.01 (the min) for everyone

  
* Agents are each group of student (node in the network): they represent geographic areas NW, NE, SE, SW
* The student-groups participate as geographic areas, they need to enter in the server as: 
 + north-west
 + north-east
 + south-east
 + south-west

* Resources:
  + unqueal for each group (grass-stored): each geographic area (one group) has an initial reservation of grass-stored their cultivation can count on
  + shared (grass-growth-rate): the speed to how fast soil regenerates, it is shared equally by all geographic area and depends on the ```sustainable tax``` they are willing to pay
 
* Scenario (cost/profit mechanisms to check, but it is the same as Tragedy of common, I did not touch it):
  + every country has an initial ```init-num-plants\farmer``` which is the same for all
  + after every ```harvest-period```, every geographic area makes profit from their agriculture: the more plants they based, the more profit they have that can spend
  + They can spend to reinvest in more plants in their area at ```cost\plant```
  + They can also spend for a ```sustainable-tax``` that affects how much the renewal of the shared grass-growth-rate will be (see below). This is the common resource

* In the front-end of each individual group (a geographic area):
  + they have an initial unequal amount of stored grass to count on
  + competition: how much plants they want to buy ```num-plants-to-buy```. The more plants, the more grass will be consumed
  + cooperation: ```sustainable-tax``` how much they want to contribute to renew grass (soil) for everyone
