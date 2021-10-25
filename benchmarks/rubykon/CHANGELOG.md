## 0.3.1 (2015-11-17)
Fixups to the CLI after the fast release.

### Bugfixes
* fix wrong magic comment in gem executable
* do not allow invalid moves in the CLI
* implement `wdyt` command to ask rubykon what it is thinking
* make FakeIO return nil on print/puts as it should be
* Allow lower case move input (a19)

## 0.3 (2015-11-16)
Implement full bot together with Monte Carlo Tree Search, as well as a more coarse grained benchmarking tool to benchmark full MCTS runs. Also add a CLI. Mostly a feature release.

### Performance
* Faster and more reliable move selection
* optimize neighbours_of by enumerating possibilities, raw but effective

### Features
* Full Monte Carlo Tree Search implementation
* Basic CLI implementation
* benchmark/avg to do more coarse grained benchmarking
* More readable string board representation
* Added License (oops)
* Added CoC

### Bugfixes
* correctly count captures for score

## 0.2 (2015-10-03)
Rewrote data representation to be smaller and do way less allocations.

### Performance
* board is now a one dimensional array with each element corresponding to one cutting point (e.g. 1-1 is 0, 3-1 is 2, 1-2 is 19 (on 19x19).
* no more stone class, the board just stores the color of the stone there. Instead of `Stone` objects, an identifier (see above) and its color are passed around.
* what would be a ko move is now stored on the game, making checking faster and easier
* dupping games is easier thanks to simpler data structures

### Bugfixes
* captures are correctly included when scoring a game

## 0.1 (2015-09-25)
Basic game version, able to perform random playouts and benchmark those.
