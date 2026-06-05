

## dataWithReward001
### Setup
#### Screen Size: 1800 by 1000
#### Objects:
##### Bot
- starts at the middle
- 54 by 54 px square centered at the center
- speed of 200
- moves by inputting data of envionment and outputting one of the actions [up,down,left,right,stay] each frame

##### Ball
- starts at the edge of the screen
- spawns at a random spot on the edge every 0.5 seconds
- 16.21 px radius (it's set by a slider..) circle
- aims at the bot's position with a random deviation of (-20,20) px on x and y
- speed of 200-400
- despawns when outside of the screen



### Train Method -- neuroevolution

#### Input (37)
For the five most dangerous balls
- relative x to ball / screen size
- relative y to ball / screen size
- ball x direction normalized
- ball y direction normalized
- dot product of the above
- speed / 400
- distance
as well as the x y position of bot divided by screen size, in total 5*7+2 = 37 inputs

#### two hidden layers
- first one with 37 by 32 dimension, applies ReLU
- second one with 32 by 32 dimension, applies ReLU
- third one with 32 by 5 dimension, applies sigmoid

#### Output
- uses argmax, picks from up,right,down,left,stay.

### Model Generation
- there are 50 generations. Each generation has 100 models. each generation have the exact same spawning of balls but different across generations
- begin by generating 100 sets of 3 weight matrices and initializing with xavier gloriot method
- put each model through simulation. 10 models with the highest scores will be kept in the next generation as well as 8 slight mutations for each of the models and 10 entirely new models.

### Rewards
- Being hit by ball     : -10 & end simulation
- Going out of bounds   : -5 & end simulation
- Survived this frame   : +0.01

### 


## dataWithReward003
### Rewards
- Being hit by ball     : -10 & end simulation
- Going out of bounds   : -5 & end simulation
- Survived this frame   : +0.01