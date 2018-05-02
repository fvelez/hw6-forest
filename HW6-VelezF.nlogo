; Felix Velez & Kevin Hernandez
; HW6

globals [

]

breed [ trees tree ]

trees-own [
  species
  life-expectancy
  max-tree-size
  max-diameter
  diameter
  growth-rate
  is-harvested?
  age
  mature-tree-mortality
  immature-tree-mortality
  fire-constant ; probability of a tree dying by fire, 0.6 for species A, 0.95 for species B (determined in setup)
  fire-resistance
  is-mature?
]

patches-own [ on-fire? ]

to setup
  ca
  reset-ticks
  ask patches [set pcolor green - 4]
  ; Create species A
  create-trees (n / 2) [
    set shape "tree"
    set species "A"
    set fire-constant 0.6
    setxy random-xcor random-ycor
    set color green + (random-float 2)
    set life-expectancy 150
    set max-tree-size 1.2
    set growth-rate (max-tree-size / life-expectancy)
    set age random life-expectancy
    ifelse age > 25 [ set is-mature? true ] [ set is-mature? false ]
    set diameter growth-rate * age
    set size growth-rate * age
    if size > max-tree-size [set size max-tree-size]
    delta-mortality
    set fire-resistance fire-constant ^ age
  ]
  ; Create species B
  create-trees (n / 2) [
    set shape "tree"
    set species "B"
    set fire-constant 0.95
    setxy random-xcor random-ycor
    set color red + (random-float 2)
    set life-expectancy 100
    set max-tree-size 1
    set growth-rate (max-tree-size / life-expectancy)
    set age random life-expectancy
    ifelse age > 25 [ set is-mature? true ] [ set is-mature? false ]
    set diameter growth-rate * age
    set size growth-rate * age
    if size > max-tree-size [set size max-tree-size]
    delta-mortality
    set fire-resistance fire-constant ^ age
  ]

  ;set immature tree colors to white for visualization regardless of species
  ask trees[
    if not is-mature?[
      set color white
    ]
  ]
end


; Is called every tick to update each tree's chances of dying as they age
to delta-mortality
  set mature-tree-mortality 0.6 ^ (life-expectancy - age)
  set immature-tree-mortality 0.3 ^ age
end


to grow
  crowded-patches
  tick ;every time this function is run, 1 year has passed in this simulation

  ; Any patches on fire slowly get darker as they burn out over 25 years.
  ask patches with [ pcolor != green - 4] [ set pcolor (pcolor - 0.2) ]

  ; When a patch has been on fire for 25 years, change back to green.
  ask patches with [ pcolor  <= 10.2 ] [ set pcolor green - 4]

  ; The color decreases after a year, so this changes their status to not on-fire
  ; (you know, since fires don't burn for more than a year)
  ask patches with [ pcolor < 15 ] [ set on-fire? false ]

  ; Ask each tree to call a function to update itself.
  ask trees with [species = "A"][
    update-trees
  ]

  ask trees with [species = "B"][
    update-trees
  ]

  ; Randomly chooses a number to compare with the chances of a forest fire.
  let fire-random random-float 1

  ; Calls the 'fire' function if the random number by chance means there is a fire
  if fire-random < fire-probability [
   fire
  ]
  burn ; calls function to decide whether a tree near a fire burns to ashes or not

  harvest ;  calls function to harvest hardwoods (species B).

  ; Forces program to wait each tick so that changes are easier to see
  wait 0.1
end


; Updates a tree's diameter, size (if possible), mortality rate, and age
to update-trees
  if age > 25 [
    set is-mature? true
    if species = "A" [ set color green + (random-float 2) ]
    if species = "B" [ set color red + (random-float 2) ]
  ]
  ; updates the tree's fire resistance according to age
  set fire-resistance fire-constant ^ age

  set diameter diameter + growth-rate
  if size < max-tree-size [
    set size size + growth-rate
  ]

  ; Increase age by one year.
  set age age + 1

  ; If tree reaches its life-expectancy, it should die of old age
  if age > life-expectancy[ set label "" die ]

  ; Update mortality rate before comparison
  delta-mortality

  ; Randomly chooses a number to compare with mortality rates
  let probability random-float 1 ;

  ; Use the different mortality rates depending on if the tree has matured or not.
  ifelse is-mature?[
    if probability < mature-tree-mortality [ die ]
  ][
    if probability < immature-tree-mortality [ die ]
  ]
  reproduce
end


; Called by observer.
; Counts mature hardwood trees and calculates how many of them
;    will be asked to die based on the harvest-rate slider.
to harvest
  ; Total number of hardwood trees
  let hardwood-tree-count count trees with [species = "A" and is-mature? = true]

  ; Number of trees to be harvested based on harvest-rate.
  let harvest-percent round (hardwood-tree-count * harvest-rate)

  ; EX: If 5 trees are to be harvested, use repeat to ask 5 hardwood trees to die.
  repeat harvest-percent[
    ask one-of trees with [species = "A" and is-mature? = true] [ die ]
  ]
end


; Called by all trees and if a tree calling it is mature,
;    generates a random value that determines if the tree
;    produces a seed or not.
to reproduce
  let probability random-float 1
  if (probability < reproduction-probability) and (is-mature? = true)[
    hatch 1[
      let random-x (xcor + 3) - (random-float 6)
      let random-y (ycor + 3) - (random-float 6)
      setxy random-x random-y
      set age 1
      set is-mature? false
      set color white
      set diameter growth-rate * life-expectancy
      set size growth-rate * age
      if size > max-tree-size [set size max-tree-size]
    ]

  ]
end


; Chooses a random patch to set on fire.
; Sets all patches within a radius of 5 to be on fire.
to fire
  ask one-of patches with [pcolor = green - 4] [
    set pcolor red
    set on-fire? true
  ]
  ;color all burning patches red for visualization
  ask patches with [on-fire? = true] [
    ask patches in-radius 5 [
      set pcolor red
      set on-fire? true
    ]
  ]
end


; Asks trees that are on a burning patch to randomly generate a number that will
;    determine whether it dies by fire or not.
to burn
  ask trees[
    if [on-fire?] of patch-here = true [
      let probability (random-float 1)
      if probability > fire-resistance [ die ]
    ]
  ]
end

 ; Ask patches if there is more than one tree on itself.
 ; If so, ask mature trees to pick the one smallest diameter and tell it to die
 ; we find that with overcrowding? on, the red trees (species B) die out very quickly
 ; we presume this may be due to them having naturally smaller diameters than species A trees
to crowded-patches
  if overcrowding?[
    ask patches [
      if count trees-here with [is-mature?] > 1[
      ask trees-here with [is-mature? = true][
        ask min-one-of trees [diameter] [die]
      ]
    ]
  ]
]
end







@#$#@#$#@
GRAPHICS-WINDOW
292
10
894
613
-1
-1
18.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
9
24
181
57
n
n
0
1000
472.0
2
1
NIL
HORIZONTAL

BUTTON
10
68
73
101
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
10
106
74
139
run
grow
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
9
144
123
193
tree A:B ratio
(count trees with [species = \"A\"]) / (count trees with [species = \"B\"])
3
1
12

SLIDER
10
198
182
231
fire-probability
fire-probability
0
1
0.06
0.01
1
NIL
HORIZONTAL

SLIDER
11
237
183
270
harvest-rate
harvest-rate
0
1
0.04
0.01
1
NIL
HORIZONTAL

SWITCH
10
323
146
356
overcrowding?
overcrowding?
1
1
-1000

SLIDER
10
280
197
313
reproduction-probability
reproduction-probability
0
1
0.07
0.01
1
NIL
HORIZONTAL

PLOT
9
364
274
581
Tree population of Species A/ B per year
years
tree count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Species A" 1.0 0 -8330359 true "" "plot count trees with [species = \"A\"]"
"Species B" 1.0 0 -2139308 true "" "plot count trees with [species = \"B\"]"

@#$#@#$#@
## HW6 - Felix Velez and Kevin Hernandez

We have neither given nor received any unauthorized aid on this assignment.

In this assignment, we simulate the growth of 2 species of trees. The details are as follows:

Species A:
• Has a longer life expectancy and larger maximum diameter, but a slower growth rate
• Is more valuable than softwoods and may be harvested.
• Is less resistant to fire
• Is colored green

Species B:
• Has a shorter life expectancy and smaller maximum diameter but faster growth rate
• Is not harvested.
• Is more resistant to fire
• Is colored red

In 1 second, 10 years will have passed in this simulation. Immature trees (trees with age less than 25 years old) are colored white for visualization, regardless of species. Also, all trees will shift colors slightly throughout the passage of time for extra prettiness. Use the sliders to change the chance of fire, reproduction rate, and the percentage of harvesting species A (green) trees.
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

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
