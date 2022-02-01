\ Animal Simulator

\ constants
10 constant HEIGHT
10 constant WIDTH
1 constant EDIBLE
-1 constant INEDIBLE
0 constant NOTHING

15 constant BASE-EDIBLE-LIFESPAN
5 constant BASE-INEDIBLE-LIFESPAN
6 constant BASE-EDIBLE-BREED-CYCLE
2 constant BASE-INEDIBLE-BREED-CYCLE

\ Type defintions
: array ( n -- )
	create cells allot ;
: } ( addr n -- addr )
	cells + ;

\ variables	
HEIGHT WIDTH * 
dup array plants{
dup array lifespans{
dup array ages{
dup array breed-cycles{
array handedness{

char q constant QUIT-KEY
variable cursor-x
variable cursor-y
false value cursor-visible?

\ pseudo-constants
: draw-cursor ." [+]" ;
: draw-cell ." [ ]" ;
: draw-edible ." [@]" ;
: draw-inedible ." [#]" ;

: >pos ( x y - n ) \ convert x and y to a number representing one location
	WIDTH * + ;

\ **************************************************************************
\ * Cursor
\ **************************************************************************

: cursor-at? ( x y -- t|f ) \ return true if cursor is at given location
	cursor-y @ = swap cursor-x @ = and ;

: cursor-down ( -- )
	cursor-y @ 1+ dup HEIGHT <
	if cursor-y ! else drop	then ;
: cursor-right ( -- )
	cursor-x @ 1+ dup WIDTH <
	if cursor-x ! else drop	then ;
: cursor-up ( -- )
	cursor-y @
	if -1 cursor-y +! then ;
: cursor-left ( -- )
	cursor-x @
	if -1 cursor-x +! then ;


\ **************************************************************************
\ * Plant Creation and Description
\ **************************************************************************

: plant-at? ( pos -- t|f ) \  return true if plant is at given location
	plants{ swap } @ NOTHING <> ;

: .lifespan ( pos --  ) \ Print lifespan of plant at pos
	dup plant-at? \ if plant exists at location
	if ." LIFESPAN:" lifespans{ swap } ?
	else drop
	then ;
	
: .age ( pos -- ) \ Print age of plant at pos
	dup plant-at? \ if plant exists at location
	if ." AGE:" ages{ swap } ?
	else drop
	then ;
	
: .breed-cycle ( pos -- ) \ print breeding cycle of plant at pos, assume zero impossible
	dup plant-at? \ if plant exists at location
	if ." BREEDING CYCLE:" breed-cycles{ swap } ?
	else drop
	then ;

: .handedness ( pos -- ) \ print handedness of plant at pos
	dup plant-at? \ if plant exists at location
	if ." HANDEDNESS:" handedness{ swap } ?
	else drop
	then ;

: add-breed-cycle ( plant-type pos -- plant-type pos ) \ expected to be called by add plant
	over 
	EDIBLE = if BASE-EDIBLE-BREED-CYCLE else BASE-INEDIBLE-BREED-CYCLE then
	over
	breed-cycles{ swap } ! ;

: add-lifespan ( plant-type pos -- plant-type pos ) \ expected to be called by add plant
	over
	EDIBLE = if BASE-EDIBLE-LIFESPAN else BASE-INEDIBLE-LIFESPAN then
	over
	lifespans{ swap } ! ;

: add-handedness ( plant-type pos -- plant-type pos )
	random 2 mod abs over handedness{ swap } ! ;

: add-plant ( plant-type pos -- ) \ create a new plant for the array
	add-lifespan
	add-breed-cycle
	add-handedness
	ages{ over } 0 swap !
	plants{ swap } ! ;
	
: remove-plant ( pos -- ) \ remove a plant in the array
	NOTHING plants{ rot ( pos ) } ! ;

\ **************************************************************************
\ * Board
\ **************************************************************************
: draw-plant-at ( x y -- ) \ if a plant is at the location draw it else draw an empty cell
	>pos plants{ swap } @ 
	case ( plant-type )
		EDIBLE of draw-edible endof
		INEDIBLE of draw-inedible endof
		draw-cell
	endcase ;

: draw-row ( n -- ) \ Take which row needs to be drawn and draw it
	WIDTH 0 do 
		i over cursor-at? cursor-visible? and
		if draw-cursor 
		else i over draw-plant-at
		then
	loop cr drop ;

: draw-board ( -- ) \ Draw the board with all plants/cursor
	cls
	HEIGHT 0 do i draw-row loop ;
	
: edit-board ( -- )
	true to cursor-visible?
	begin
	draw-board ." Press q to quit"
	cursor-x @ cursor-y @ >pos
	dup cr .age
	dup cr .lifespan
	dup cr .breed-cycle
	cr .handedness
	key dup QUIT-KEY <>
	while
		case ( key )
			[char] w of cursor-up endof
			[char] s of cursor-down endof
			[char] a of cursor-left endof
			[char] d of cursor-right endof
			[char] @ of EDIBLE cursor-x @ cursor-y @ >pos add-plant endof
			[char] # of INEDIBLE cursor-x @ cursor-y @ >pos add-plant endof
			32 ( space ) of cursor-x @ cursor-y @ >pos remove-plant endof
		endcase
	repeat drop 
	false to cursor-visible?
	draw-board ;


\ **************************************************************************
\ * Simulation
\ **************************************************************************

: inc-age ( pos -- ) \ assume plant at pos, increment age of plant
	1 ages{ rot } +! ;

: dead? ( pos -- t|f ) \ assume plant at pos, return true if it has died
	lifespans{ over ( pos ) } @  ages{ rot ( pos ) } @ <= ;
: die ( pos -- ) \ remove the plant at pos
	NOTHING plants{ rot } ! ;

\ **** words for returning positions around a given cell   ****
\ **** return negative to represent out of bounds position ****
 HEIGHT WIDTH * invert constant MAX-OUT-OF-BOUNDS
: dx ( pos n -- pos ) + ; \ return position equivalent to adding the x value 
: dy ( pos n -- pos ) WIDTH * + ; \ return position equivalent to adding the y value

: top          ( pos1 -- pos2 ) 
	dup WIDTH < if drop MAX-OUT-OF-BOUNDS
	else -1 dy then ;
: bottom       ( pos1 -- pos2 ) 
	dup HEIGHT 1- WIDTH * > if drop MAX-OUT-OF-BOUNDS
	else 1 dy then ;
: left         ( pos1 -- pos2 )
	dup WIDTH mod 0=  if drop MAX-OUT-OF-BOUNDS
	else -1 dx then ;
: right        ( pos1 -- pos2 )
	dup 1+ WIDTH mod 0= if drop MAX-OUT-OF-BOUNDS
	else 1 dx then ;
: in-bounds?   ( pos? -- t|f ) 0 >= ;

: nth-neighbour ( pos n -- pos ) \ return the nth neighbour of pos
	over handedness{ swap } @ 
	if -7 + then  \ if left handed then reverse order
	case 
		-1 of drop MAX-OUT-OF-BOUNDS endof 
		0 of top left endof
		1 of top right endof
		2 of bottom left endof
		3 of bottom right endof
		4 of left endof
		5 of top endof
		6 of right endof
		7 of bottom endof
		8 of drop MAX-OUT-OF-BOUNDS endof
	endcase ;

: space-for-seed ( pos1 -- pos2 ) \ Check surrounding cells for empty space
	-1 \ count
	begin
		1+ \ increment counter
		2dup ( pos1 count )
		nth-neighbour dup in-bounds? 
		if plant-at? not \ if pos in bounds, check that space is empty
		else drop false  \ if pos is out of bounds, space is not available
		then
		over 8 = \ count=8
		or
	until \ post: count=8 XOR ~(plant at pos nth)
	( pos1 count )
	dup 8 < \ if less than 8, space was found 
	if nth-neighbour
	else 2drop MAX-OUT-OF-BOUNDS
	then ;  \ return cell containing space (out of bounds if no space found)

: same-species? ( pos1 pos2 -- t|f ) \ Return true if plants at positions are the same species
	plants{ swap } @ swap plants{ swap } @ = ;

: compatible-neighbour ( pos1 -- pos2 ) \ Check surrounding cells for a compatible neighbour
	-1 \ count
	begin
		1+ \ increment counter
		2dup over swap ( pos1 count pos1 pos1 count )
		nth-neighbour dup in-bounds? 
		if 
			same-species?
		else 
			2drop false  \ if pos is out of bounds, space is not available
		then
		over 8 = \ count=8
		or
	until \ post: count=8 XOR ~(neighbour at nth)
	( pos1 count )
	dup 8 < \ if less than 8, compatible neighbour was found 
	if nth-neighbour
	else 2drop MAX-OUT-OF-BOUNDS
	then ;  \ return compatible neighbour (out of bounds if no space found)

: breed-ready? ( pos -- t|f) \ assume plant at pos, return true if it is ready to breed
	ages{ over } @ breed-cycles{ rot } @ 2dup 
	>= -rot 
	mod 0= \ age is a multiple of breed-cycle
	and ;
			
: breed ( pos -- ) \ breed plant at pos
	dup space-for-seed
	swap compatible-neighbour
	2dup in-bounds? swap in-bounds? and
	if ( space neighbour )
		\ TODO: gene crossing with neighbour
		plants{ swap } @ swap add-plant
	else 2drop
	then ;

: step ( -- ) \ simulate a single cycle
	WIDTH HEIGHT * 0 do
		i plant-at? 
		if 
			i dead? if i die else i inc-age then
			i breed-ready? if i breed then
		then
	loop ;
	
: .step ( -- ) \ simulate a single cycle and draw it
	step draw-board ;

: simulate ( n -- ) \ simulate for n number of steps
	0 do step loop ;
