rect:
push eax ; 12
push ebx ; 8
push ecx ; 4
push edx ; 0

mov esi, [lfb_addr]  
mov edx, [lfb_pitch]  

mov eax, [esp + 8]
mov ebx, [esp]
sub ebx, eax
imul eax, edx
add esi, eax

row_loop_rect:
mov edi, esi
mov eax, [esp + 12]
mov ecx, [esp + 4]
sub ecx, eax 
imul eax, 3              
add edi, eax         

pixel_loop_rect:
mov byte [edi], 0x00
mov byte [edi+1], 0x00
mov byte [edi+2], 0xFF 
add edi, 3
dec ecx
jnz pixel_loop_rect

add esi, edx        
dec ebx
jnz row_loop_rect
ret