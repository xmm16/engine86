pusha

line:
mov eax, 0 ; x1
mov ebx, 0 ; y1
mov ecx, 80 ; x2
mov edx, 80 ; y2

mov edi, edx
sub edx, ebx
mov esi, ecx
sub esi, eax

; xmm0 = edi / esi
; xmm0 used to be edi, so replace accordingly
cvtsi2ss xmm0, edi
cvtsi2ss xmm1, esi
divss xmm0, xmm1
; slope in xmm0

mov esi, ebx
push ecx
mov ecx, edi
imul ecx, eax
sub esi, ecx ; integer y-intercept in esi
pop ecx

; rectangle should be from x1 -> x1 + 1
; y1 -> y1 + (y1 * slope + y-int)

push eax ; 20->16 x1
push ebx ; 16->12 y1
push ecx ; 12->8 x2
push edx ; 8->4 y2
push esi ; 0 y-int

mov esi, [lfb_addr]  
mov edx, [lfb_pitch]  

line_loop:
mov eax, [esp + 12] ; y1
mov ebx, [esp + 16] ; x1
cvtsi2ss xmm1, ebx
mulss xmm0, xmm1
cvttss2si ebx, xmm0
add ebx, [esp] ; now y2
mov [esp + 12], ebx

sub ebx, eax
imul eax, edx
add esi, eax

row_loop:
mov edi, esi
mov eax, [esp + 16]
cmp eax, [esp + 8]
jge line_done

mov ecx, eax
inc ecx
mov [esp + 16], ecx

sub ecx, eax
imul eax, 3
add edi, eax

pixel_loop:
mov byte [edi], 0x00
mov byte [edi + 1], 0x00
mov byte [edi + 2], 0xFF
add edi, 3
dec ecx
jnz pixel_loop

add esi, edx
dec ebx
jnz row_loop

line_done:
hlt
