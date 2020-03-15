.386
.model flat, c


; These symbols provide a link with the emulator code:
public screen_pixels
public keyboard_state


; The following definitions are used in the data and code segments below. All
; of the calculations here can be performed by the assembler program before
; attempting to generate the machine code. Although these values could be
; precalculated and inserted directly into the code, leaving the derivation
; of these numbers here helps to document the program. It also provides a
; single point to tweak many of the parameters in the game, and have those
; changes applied automatically and consistently through the program.
screen_width        = 640
screen_height       = 480
screen_x_centre     = screen_width / 2
screen_y_centre     = screen_height / 2
screen_width_bytes  = screen_width / 8
ball_x_scale        = 0
ball_y_scale        = 0
ball_width          = 15 shl ball_x_scale
ball_height         = 15 shl ball_y_scale
paddle_x_scale      = 0
paddle_y_scale      = 6
paddle_width        = 15 shl paddle_x_scale
paddle_height       = 1 shl paddle_y_scale
net_x_scale         = 0
net_y_scale         = 4
net_width           = 7 shl net_x_scale
net_height          = 31 shl net_y_scale
number_x_scale      = 3
number_y_scale      = 3
number_width        = 3 shl number_x_scale
number_height       = 5 shl number_y_scale
number_bitmap_size  = 5
keypress_bitmask    = 080h
reset_keycode       = 01bh
p1_up_keycode       = "A"
p1_down_keycode     = "Z"
p2_up_keycode       = 026h
p2_down_keycode     = 028h
ball_x_start        = screen_x_centre
ball_y_start        = screen_y_centre
ball_vx_start       = 8
ball_vy_start       = 8
paddle_y_velocity   = 8
p1_x_start          = paddle_width / 2
p1_y_start          = screen_y_centre
p2_x_start          = screen_width - (paddle_width / 2)
p2_y_start          = screen_y_centre
p1_score_x          = screen_width / 4
p1_score_y          = number_height
p2_score_x          = screen_width - (screen_width / 4)
p2_score_y          = number_height
maximum_score       = 9

.data
     ; These data items represent the state of the game:
     ball_x_position     dword     ball_x_start
     ball_y_position     dword     ball_y_start
     ball_x_velocity     dword     ball_vx_start
     ball_y_velocity     dword     ball_vy_start
     p1_score            dword     0
     p2_score            dword     0
     p1_paddle_x         dword     p1_x_start
     p1_paddle_y         dword     p1_y_start
     p2_paddle_x         dword     p2_x_start
     p2_paddle_y         dword     p2_y_start

     ; These two items provide the link to the emulator code.
     screen_pixels       dword     ?
     keyboard_state      dword     ?

     ; The following data items provide the bitmap data for drawing the parts
     ; of the game. Each is encoded with 1 bit representing 1 pixel. In each
     ; byte, the most significant bit represents the left most pixel and
     ; each subsequent bit represent the next pixel to the right. Each line
     ; of the bitmap starts with a new byte so any bits to the right of the
     ; last pixel are ignored.

     ball_pixels         byte      007h, 0c0h
                         byte      01fh, 0f0h
                         byte      03fh, 0f8h
                         byte      07fh, 0fch
                         byte      07fh, 0fch
                         byte      0ffh, 0feh
                         byte      0ffh, 0feh
                         byte      0ffh, 0feh
                         byte      0ffh, 0feh
                         byte      0ffh, 0feh
                         byte      07fh, 0fch
                         byte      07fh, 0fch
                         byte      03fh, 0f8h
                         byte      01fh, 0f0h
                         byte      007h, 0c0h

     paddle_pixels       byte      0ffh, 0feh

     net_pixels          byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh, 000h
                         byte      0feh

     numbers             byte      0e0h, 0a0h, 0a0h, 0a0h, 0e0h
                         byte      040h, 040h, 040h, 040h, 040h
                         byte      0e0h, 020h, 0e0h, 080h, 0e0h
                         byte      0e0h, 020h, 0e0h, 020h, 0e0h
                         byte      0a0h, 0a0h, 0e0h, 020h, 020h
                         byte      0e0h, 080h, 0e0h, 020h, 0e0h
                         byte      0e0h, 080h, 0e0h, 0a0h, 0e0h
                         byte      0e0h, 020h, 020h, 020h, 020h
                         byte      0e0h, 0a0h, 0e0h, 0a0h, 0e0h
                         byte      0e0h, 0a0h, 0e0h, 020h, 020h

.code

machine_code_program proc

     ; Check for the escape key (keycode 27) being pressed. The keymap is a 
     ; simple list of bytes in keycode order, so we need to check the byte at
     ; start of the keyboard state map + 27. A key is pressed if the top bit
     ; of the byte is set. We test this by performing AND on byte and a
     ; "mask" with the top bit set. This sets the zero flag to 0 or 1
     ; depending on this top bit:
     mov       eax, [keyboard_state]
     and       byte ptr [eax+reset_keycode], keypress_bitmask

     ; If the button hasn't been pressed, then skip the reset instructions...
     je        check_p1_up

     ; otherwise reset the game's state data:
     mov       [p1_score], 0
     mov       [p2_score], 0
     mov       [ball_x_position], ball_x_start
     mov       [ball_y_position], ball_y_start
     mov       [ball_x_velocity], ball_vx_start 
     mov       [ball_y_velocity], ball_vy_start 
     mov       [p1_paddle_x], p1_x_start 
     mov       [p1_paddle_y], p1_y_start 
     mov       [p2_paddle_x], p2_x_start 
     mov       [p2_paddle_y], p2_y_start

; Check for player 1 up key being pressed...
check_p1_up:
     and       byte ptr [eax+p1_up_keycode], keypress_bitmask

     ; if not, skip to the next check...
     je        check_p1_down

     ; otherwise move the player 1 paddle up:
     mov       ebx, [p1_paddle_y]
     sub       ebx, paddle_y_velocity

     ; Check if the new position of the player 1 paddle is off the top of the
     ; screen...
     cmp       ebx, paddle_height / 2

     ; if not, then store the new position...
     jge       store_p1_up

     ; otherwise, set the new position to the top of the screen:
     mov       ebx, paddle_height / 2

; Store the new position of paddle 1 in memory:
store_p1_up:
     mov       [p1_paddle_y], ebx


; Check for player 1 down key being pressed...
check_p1_down:
     and       byte ptr [eax+p1_down_keycode], keypress_bitmask

     ; if not, skip to the next check...
     je        check_p2_up

     ; otherwise move the player 1 paddle down:
     mov       ebx, [p1_paddle_y]
     add       ebx, paddle_y_velocity

     ; Check if the new position of the player 1 paddle is off the bottom of
     ; the screen...
     cmp       ebx, screen_height - paddle_height / 2

     ; if not, then store the new position...
     jle       store_p1_down

     ; otherwise, set the new position to the bottom of the screen:
     mov       ebx, screen_height - paddle_height / 2

; Store the new position of paddle 1 in memory.
store_p1_down:
     mov       [p1_paddle_y], ebx

; Check for player 2 up key being pressed...
check_p2_up:
     and       byte ptr [eax+p2_up_keycode], keypress_bitmask

     ; if not, skip to the next check...
     je        check_p2_down

     ; otherwise move the player 2 paddle up:
     mov       ebx, [p2_paddle_y]
     sub       ebx, paddle_y_velocity

     ; Check if the new position of the player 2 paddle is off the top of the
     ; screen...
     cmp       ebx, paddle_height / 2

     ; if not, then store the new position...
     jge       store_p2_up

     ; otherwise, set the new position to the top of the screen:
     mov       ebx, paddle_height / 2

; Store the new position of paddle 2 in memory.
store_p2_up:
     mov       [p2_paddle_y], ebx

; Check for player 2 down key being pressed...
check_p2_down:
     and       byte ptr [eax+p2_down_keycode], keypress_bitmask

     ; if not, skip to the next check...
     je        check_game_over

     ; otherwise move the player 2 paddle down:
     mov       ebx, [p2_paddle_y]
     add       ebx, paddle_y_velocity

     ; Check if the new position of the player 2 paddle is off the bottom of
     ; the screen...
     cmp       ebx, screen_height - paddle_height / 2

     ; if not, then store the new position...
     jle       store_p2_down

     ; otherwise, set the new position to the bottom of the screen:
     mov       ebx, screen_height - paddle_height / 2

; Store the new position of paddle 2 in memory.
store_p2_down:
     mov       [p2_paddle_y], ebx

; Check to see if either player has scored maximum points and if so, skip to
; the draw code...
check_game_over:
     cmp       [p1_score], maximum_score
     je        draw_game
     cmp       [p2_score], maximum_score
     je        draw_game

     ; otherwise, update the ball position:
     mov       ebx, [ball_x_velocity]
     add       [ball_x_position], ebx
     mov       ebx, [ball_y_velocity]
     add       [ball_y_position], ebx

; Check if the new ball position crosses the top or bottom of the screen...
; if so then invert the ball velocity, otherwise skip to the next check:
check_top_and_bottom:
     mov       eax, [ball_y_position]
     cmp       eax, 0
     jl        invert_ball_y_velocity
     cmp       eax, screen_height
     jge       invert_ball_y_velocity
     jmp       check_p1_paddle_hit

invert_ball_y_velocity:
     neg       [ball_y_velocity]

; Check if the ball has hit or passed the player 1 paddle...
check_p1_paddle_hit:
     ; if the ball is going to the right, then skip to check player 2...
     cmp       [ball_x_velocity], 0
     jg        check_p2_paddle_hit

     ; otherwise, compare the x positions of the ball and player 1 paddle...
     ; if the ball is to the right of the paddle, skip to check player 2...
     mov       eax, [ball_x_position]
     mov       ecx, [p1_paddle_x]
     sub       eax, ecx
     cmp       eax, (paddle_width + ball_width) / 2
     jg        check_p2_paddle_hit

     ; otherwise, compare the y positions of the ball and player 1 paddle...
     ; if the ball is above or below the paddle, skip to check if the ball
     ; has passed the paddle, otherwise skip to hit the paddle:
     mov       ebx, [ball_y_position]
     mov       ecx, [p1_paddle_y]
     sub       ecx, ebx
     cmp       ecx, (paddle_height + ball_height) / 2
     jg        check_score_p2
     cmp       ecx, -(paddle_height + ball_height) / 2
     jg        hit_p1

; Check if the ball is off the left of the screen...
check_score_p2:
     cmp       eax, 0

     ; if so, then score a point for player 2...
     jl        score_p2

     ; otherwise skip to check player 2...
     jmp       check_p2_paddle_hit

; When the ball hits the paddle, negate the x velocity to bounce it...
hit_p1:
     neg       [ball_x_velocity]

     ; then skip to check player 2...
     jmp       check_p2_paddle_hit

; When player 2 has scored a point...
score_p2:
     ; check for maximum points...
     mov       eax, [p2_score]
     cmp       eax, maximum_score

     ; if already at maximum, just reset the ball...
     jge       reset_ball

     ; otherwise add 1 to the player 2 score:
     inc       eax
     mov       [p2_score], eax

; Reset the ball x and y position and negate its current x velocity:
reset_ball:
     mov       [ball_x_position], ball_x_start
     mov       [ball_y_position], ball_y_start
     neg       [ball_x_velocity]

     ; Skip straight to the draw code:
     jmp       draw_game

; Check if the ball has hit or passed the player 2 paddle...
check_p2_paddle_hit:
     ; if the ball is going to the left, then skip to draw code...
     cmp       [ball_x_velocity], 0
     jl        draw_game

     ; otherwise, compare the x positions of the ball and player 2 paddle...
     ; if the ball is to the left of the paddle, skip to draw code...
     mov       eax, [ball_x_position]
     mov       ecx, [p2_paddle_x]
     sub       ecx, eax
     cmp       ecx, (paddle_width + ball_width) / 2
     jg        draw_game

     ; otherwise, compare the y positions of the ball and player 2 paddle...
     ; if the ball is above or below the paddle, skip to check if the ball
     ; has passed the paddle, otherwise skip to hit the paddle:
     mov       ebx, [ball_y_position]
     mov       ecx, [p2_paddle_y]
     sub       ecx, ebx
     cmp       ecx, (paddle_height + ball_height) / 2
     jg        check_score_p1
     cmp       ecx, -(paddle_height + ball_height) / 2
     jg        hit_p2

; Check if the ball is off the right of the screen...
check_score_p1:
     cmp       eax, screen_width

     ; if so, then score a point for player 1...
     jg        score_p1

     ; otherwise skip to the draw code:
     jmp       draw_game


; When the ball hits the paddle, negate the x velocity to bounce it...
hit_p2:
     neg       [ball_x_velocity]

     ; then skip to the draw code:
     jmp       draw_game

; When player 1 has scored a point...
score_p1:
     ; check for maximum points...
     mov       eax, [p1_score]
     cmp       eax, maximum_score

     ; if already at maximum, just reset the ball...
     jge       reset_ball

     ; otherwise add 1 to the player 1 score...
     inc       eax
     mov       [p1_score], eax

     ; then reset the ball:
     jmp       reset_ball

; Draw the game by first clearing the screen, and then drawing each of the
; game elements in their current positions.
draw_game:
     ; Using the B register to store the screen start and the A register as
     ; an index:
     mov       ebx, [screen_pixels]
     mov       eax, 0

; Loop to clear the screen one byte at a time...
clear_screen_byte:
     mov       byte ptr [ebx+eax], 0
     inc       eax
     cmp       eax, screen_height*screen_width_bytes
     jl        clear_screen_byte

     ; Draw the ball at ball_x_position, ball_y_position:
     push      ball_y_scale
     push      ball_x_scale
     push      ball_height
     push      ball_width
     mov       eax, [ball_y_position]
     push      eax
     mov       eax, [ball_x_position]
     push      eax
     lea       eax, ball_pixels
     push      eax
     call      draw_sprite
     add       esp, 28

     ; Draw player 1 paddle:
     push      paddle_y_scale
     push      paddle_x_scale
     push      paddle_height
     push      paddle_width
     mov       eax, [p1_paddle_y]
     push      eax
     mov       eax, [p1_paddle_x]
     push      eax
     lea       eax, paddle_pixels
     push      eax
     call      draw_sprite
     add       esp, 28

     ; Draw player 2 paddle:
     push      paddle_y_scale
     push      paddle_x_scale
     push      paddle_height
     push      paddle_width
     mov       eax, [p2_paddle_y]
     push      eax
     mov       eax, [p2_paddle_x]
     push      eax
     lea       eax, paddle_pixels
     push      eax
     call      draw_sprite
     add       esp, 28

     ; Draw player 1 score...
     push      number_y_scale
     push      number_x_scale
     push      number_height
     push      number_width
     mov       eax, [p1_score_y]
     push      eax
     mov       eax, [p1_score_x]
     push      eax

     ; find the bitmap representing the player 1's current score by 
     ; multiplying the score by the size of the number bitmaps and adding
     ; that as an offset to the beginning of the number bitmaps:
     lea       eax, numbers
     mov       ebx, [p1_score]
     imul      ebx, number_bitmap_size
     add       eax, ebx
     push      eax
     call      draw_sprite
     add       esp, 28

     ; Draw player 2 score finding the number bitmap offset as above:
     push      number_y_scale
     push      number_x_scale
     push      number_height
     push      number_width
     mov       eax, [p2_score_y]
     push      eax
     mov       eax, [p2_score_x]
     push      eax
     lea       eax, numbers
     mov       ebx, [p2_score]
     imul      ebx, number_bitmap_size
     add       eax, ebx
     push      eax
     call      draw_sprite
     add       esp, 28

     ; Draw the net:
     push      net_y_scale
     push      net_x_scale
     push      net_height
     push      net_width
     mov       eax, screen_y_centre
     push      eax
     mov       eax, screen_x_centre
     push      eax
     lea       eax, net_pixels
     push      eax
     call      draw_sprite
     add       esp, 28

     ; Finished the game loop:
     ret

machine_code_program endp



draw_sprite proc

; Offsets from base pointer for each parameter passed on the stack:
sprite_pixels       = 8
sprite_x_position   = 12
sprite_y_position   = 16
sprite_width        = 20
sprite_height       = 24
sprite_x_scale      = 28
sprite_y_scale      = 32

; Offsets from base pointer for temporary space on the stack:
half_height         = 4
half_width          = 8
bytes_width         = 12

     ; Conventional subroutine prologue to store the current base pointer and
     ; make some room on the stack for temporary data:
     push      ebp
     mov       ebp, esp
     sub       esp, 12

     ; Calculate half the sprite width and half the sprite height and store
     ; them as temporary values. Will use these as offsets in the rest of
     ; this subroutine:
     mov       eax, [ebp+sprite_height]
     mov       ebx, eax
     shr       ebx, 1
     mov       [ebp-half_height], ebx
     mov       ebx, [ebp+sprite_width]
     shr       ebx, 1
     mov       [ebp-half_width], ebx

     ; Divide the width by the X scale to get the sprite size in pixels...
     mov       ecx, [ebp+sprite_x_scale]
     mov       ebx, [ebp+sprite_width]
     shr       ebx, cl

     ; then add 7, and then divide by 8 to get the sprite width in bytes
     ; rounded up to the nearest byte:
     add       ebx, 7
     shr       ebx, 3
     mov       [ebp-bytes_width], ebx

; Loop for every line we want to draw from bottom to top. (Register eax is
; already loaded with the height from above):
draw_next_sprite_line:
     ; Check if we just drawn the last line...
     dec       eax

     ; if so, skip to the end...
     jl        done_sprite_draw

     ; otherwise, calculate the screen Y coordinate for this line in ecx...
     mov       ecx, [ebp+sprite_y_position]
     sub       ecx, [ebp-half_height]
     add       ecx, eax

     ; if it's off the top of the screen, skip to the next line...
     jl        draw_next_sprite_line

     ; if it's off the bottom of the screen, skip to the next line...
     cmp       ecx, screen_height
     jge       draw_next_sprite_line

     ; otherwise set the ebx register to the width:
     mov       ebx, [ebp+sprite_width]

; Loop for every pixel we want to draw from right to left.
draw_next_sprite_pixel:
     ; Check if we just drew the last pixel...
     dec       ebx

     ; if so, skip to the next line...
     jl        draw_next_sprite_line

     ; otherwise calculate the screen X coordinate for this pixel in edx...
     mov       edx, [ebp+sprite_x_position]
     sub       edx, [ebp-half_width]
     add       edx, ebx

     ; if it's off the left of the screen, skip to the next pixel...
     jl        draw_next_sprite_pixel

     ; if it's off the right of the screen, skip to the next pixel:
     cmp       edx, screen_width
     jge       draw_next_sprite_pixel

     ; Convert from screen coordinates Y in ecx and X in edx to a byte 
     ; pointer in edi and a bit index in edx. First set edi to point to
     ; the offset representing the start of the line number stored in ecx...
     mov       edi, ecx
     imul      edi, screen_width_bytes

     ; temporarily store eax on the stack to re-use the register...
     push      eax

     ; set eax to (X position / 8)...
     mov       eax, edx
     shr       eax, 3

     ; add eax and the address of the start of the screen to get the final
     ; byte offset in edi...
     add       edi, eax
     add       edi, [screen_pixels]

     ; set edx to the bit index of the pixel coordinate that is the
     ; remainder of (X position / 8)...
     and       edx, 7
     sub       edx, 7
     neg       edx

     ; restore eax from the stack:
     pop       eax

     ; Convert from sprite coordinates Y in eax and X in ebx to a byte 
     ; pointer in esi and bit index in eax. First temporarily store ecx on
     ; the stack to allow re-use of that register...
     push      ecx

     ; set esi to (Y position / Y scale) * (sprite width in bytes)
     mov       esi, eax
     mov       ecx, [ebp+sprite_y_scale]
     shr       esi, cl
     imul      esi, [ebp-bytes_width]

     ; temporarily store eax on the stack to allow re-use of that register...
     push      eax

     ; set eax to (X position / X scale / 8)...
     mov       eax, ebx
     mov       ecx, [ebp+sprite_x_scale]
     shr       eax, cl
     shr       eax, 3

     ; add eax and the sprite pixel bitmap address to get the final byte
     ; offset in esi...
     add       esi, eax
     add       esi, [ebp+sprite_pixels]

     ; set eax to the bit index of the pixel coordinate that is the
     ; remainder of (X sprite position / X scale / 8)...
     mov       eax, ebx
     shr       eax, cl
     and       eax, 7
     sub       eax, 7
     neg       eax

     ; copy the screen bit index from D to C so we can use D as a
     ; temporary...
     mov       ecx, edx

     ; copy the bit from the sprite to the bit in screen memory using the
     ; D as a temporary...
     mov       dl, byte ptr [esi]
     bt        edx, eax
     setc      dl
     shl       edx, cl        
     or        byte ptr [edi], dl

     ; restore eax to the screen Y offset...
     pop       eax

     ; restore eax to the sprite Y offset...
     pop       ecx

     ; loop to the next pixel
     jmp       draw_next_sprite_pixel

; This is the draw loop exit:
done_sprite_draw:
     
     ; Conventional subroutine epilogue to restore the stack and base pointer
     ; registers and return to the caller:
     mov       esp, ebp
     pop       ebp
     ret

draw_sprite endp

end
