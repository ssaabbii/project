asect 0x00

arr:     #local game data: empty, nought or cross 
	dc 0, 0, 0, 0       #0000 0001 0010  |  0011  3 and 7 is unused due to the specifics of BPC
	dc 0, 0, 0, 0       #0100 0101 0110  |  0111
	dc 0, 0, 0          #1000 1001 1010  |

table:
	dc 0,1,2  #pointers on rows
	dc 4,5,6 
	dc 8,9,10 
	dc 0,4,8  #columns
	dc 1,5,9
	dc 2,6,10
	dc 0,5,10 #diagonals
	dc 2,5,8
	dc -1     #to move while greater then or equal to zero
	
addsp -16 #move stack pointer(to avoid replacing f3) 

playerturn:
ldi r0, 0xf3     # load the button id in r0
while
	ld r0, r1
	tst r1       # wait for data (while zero do nothing)
stays eq
wend                        # 1000XXYY got this
ldi r3, 0b00001111          # bitmask to get rid of enable bit
and r3,r1                   # 0000XXYY prepare to send coords and symID 
ldi r2, 2
st r1, r2
shla r1
shla r1                     # 00XXYY00
add r2,r1                   # 00XXYY10 -> ready to send right coords and symID to SDR
st r0 ,r1
jsr drawcounter
jsr wincheck
jsr computerturn

wincheck:
ldi r3, table 
while
	ldc r3, r0 #ldc - loads a constant at the address specified in the first register
	tst r0 
stays ge # until we moved to -1 in the table
	ldc r3,r0
	inc r3
	ldc r3,r1
	inc r3
	ld r0, r0
	ld r1,r1
	if 
		cmp r0,r1
	is eq
		if 
			tst r0
		is ne
			ldc r3, r0  
			ld r0, r0
			if 
				cmp r0,r1  #comparing if three symbols are same
			is eq
				if
					dec r1
					tst r1   
				is eq      #three noughts = lose 
					br lose #nought is 1, dec 1 = 0
				else       #three crosses = win
					br win
				fi
			fi
		fi
	fi
	inc r3 #move to next table address
wend
ldi r3,arr+3 
ld r3, r0
ldi r1, 9 
if
	cmp r1, r0  #if draw counter is 9 -> no empty space, its draw game state
is eq
br draw
fi
rts #return from subroutine
        
lose:
ldi r0, 0xf3
ldi r1, 0x40 # 01 - bits to GSDD
ldi r2, arr  # few lines to avoid removing first cell 
ld r2, r2    # if we send XX000000 there will be an empty cell
add r2, r1   # in 0000 coords on the matrix connected to TTTC chip
st r0, r1
halt

win:
ldi r0, 0xf3
ldi r1, 0x80 # 10 - bits to GSDD
ldi r2, arr  #
ld r2, r2    #
add r2, r1   #
st r0, r1
halt

draw: 
ldi r0, 0xf3
ldi r1, 0xC0 # 11 - bits to GSDD
ldi r2, arr  #
ld r2, r2    #
add r2, r1   #
st r0, r1
halt

drawcounter:
ldi r3, arr+3 # noughts + crosses counter located in arr+3 cell                
ld r3, r0
inc r0
st r3, r0 
rts

computerturn:
ldi r3, table   
while
	ldc r3, r0
	tst r0
stays ge #until "-1"
	ldc r3, r0
	inc r3
	ldc r3, r1     
	inc r3
	ldc r3, r2
	ld r0, r0
	ld r1, r1 
	if
	cmp r1, r0 # move through the table
	is eq  # check if first two in a row/col/diag are the same and not nothing (*)
		if               
			tst r1
		is ne
			if
				move r2, r1
				ld r1, r1
				tst r1
			is eq
				ldi r1, 1  # put nought if condition (*)
				st r2, r1  
				shla r2
				shla r2
				add r1, r2
				ldi r0, 0xf3
				st r0, r2
				jsr drawcounter
				jsr wincheck
				jsr playerturn
			fi
		fi
	fi
	inc r3 #move to next table address
wend
ldi r0, table  # if (*) not encountered
while           
	ldc r0, r1
	ld r1, r1
	tst r1     #find first empty cell
stays ne
	inc r0
wend
ldc r0, r0
ldi r2, 1 #put nought in that cell on a board        
st r0, r2
shla r0
shla r0
add r2, r0
ldi r1, 0xf3
st r1, r0

jsr drawcounter
jsr wincheck
jsr playerturn

end