# Possible Improvements

Possible improvements to try out in the implementation :)

## Playout speed

### Board representation
* Reuse stones instead of creating new ones (would probably require a separate move class)
* just use symbols on the board instead of full fledged objects
* use a one dimensional array as the board (can map back to original using modulo etc.)
* use multiple bitmasks (or a bigger one) to represent board state (we have 3 states so a simple mask won't do)
* neighbour_colors methods

### Group
* remove references to stones/liberties from obsolete groups (when it is merged in another group or taken off the board)
* in liberties, don't point to stones but point to groups (be careful as no group is nil... and that then is not good with hash lookups)

### Move gen
* check self atari?

### Scoring
* use more efficient scoring algorithm (michi floodfill like?)

### Move generation
* sensibly choose moves and not just that random barrage... possiby using an Enumerator