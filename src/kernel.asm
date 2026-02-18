org 0x7e00
bits 16

%define WIDTH 1600
%define HEIGHT 1052
%define PIXEL_SIZE 3
%define SAMPLES_PER_AXIS 3
%define SAMPLES_PER_AXIS_SQ 9 ; samples per axis squared
%define MAX_DEPTH 2
%define FOV 42
%define EPSILON 0.00001

%define CORE_NUM 22
%define FPS  60

%define COL_FLOOR_0 255.0
%define COL_FLOOR_1 255.0
%define COL_FLOOR_2 255.0

%define COL_MIRROR_0 25.5
%define COL_MIRROR_1 25.5
%define COL_MIRROR_2 25.5

%define COL_LIGHT_0 5610.0
%define COL_LIGHT_1 3825.0
%define COL_LIGHT_2 510.0

%define COL_SKY_0 1.275
%define COL_SKY_1 1.275
%define COL_SKY_2 2.55

section .data
align 4
lfb_addr:  dd 0
mode_info: times 256 db 0
XMM_GV_SIGN_MASK: dd 0x80000000 ; 10000000000000000000000000000000000000000000000

align 8
gdt:
    dq 0x0000000000000000
    dq 0x00cf9a000000ffff
    dq 0x00cf92000000ffff
gdt_desc:
    dw gdt_desc - gdt - 1
    dd gdt

mcs_end:

section .bss
section .text
kernel_init:
    mov ax, 0x4f02
    mov bx, 0x11f | 0x4000
    int 0x10

    mov ax, 0x4f01
    mov cx, 0x11f
    mov di, mode_info
    int 0x10

    mov eax, [mode_info + 0x28]
    mov [lfb_addr], eax

    in al, 0x92
    or al, 2
    out 0x92, al

    lgdt [gdt_desc]
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    jmp 0x08:pm_start

bits 32
pm_start:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, 0x9FFF0

    mov esi, ap_mcs
    mov edi, 0x10000
    mov ecx, mcs_end - ap_mcs
    rep movsb

    mov eax, 0xFEE00300
    mov edx, 0x000C4500
    mov [eax], edx

    mov ecx, 0x1000000
.delay: 
    loop .delay

    mov edx, 0x000C4610
    mov [eax], edx

    jmp parallel

bits 16
ap_mcs:
    cli
    xor ax, ax
    mov ds, ax
    lgdt [gdt_desc] 
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:ap_pm_entry
ap_mcs_end:

bits 32
ap_pm_entry:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax
    
    mov eax, 0xFEE00020
    mov ebx, [eax]
    shr ebx, 24              
    ; right now 50 triangles per core sample
    ; and 1000 bytes worplace
    mov eax, 100*50 + 4 + 1000  ; max size of the stack for the core, 100*NUM_TRIANGLES + SIZE_OF_NUMBER_OF_TRIANGLES + SIZE_OF_WORKPLACE all in bytes
    mul ebx ; ebx stays the same
    mov esp, 0x9FFF0 ; stack begin!
    sub esp, eax
    add esp, 1000
    and esp, -64 ; align to 64 bytes
    jmp parallel

make_triangle:
    %define make_cube_ARG_triangle_parameters esi
    mov 
    vmovaps xmm0, [make_cube_ARG_triangle_parameters]
    vmovaps xmm1, [make_cube_ARG_triangle_parameters + 4]
    vmovaps xmm2, [make_cube_ARG_triangle_parameters + 4*2]
    vmovaps xmm2, [make_cube_ARG_triangle_parameters + 4*3]
    

    ret

make_cube:
    %define pos_x ebp-4
    %define pos_y ebp-4*2
    %define pos_z ebp-4*3

    %define size ebp-4*4

    %define color_x ebp-4*5
    %define color_y ebp-4*6
    %define color_z ebp-4*7

    %define mat ebp-4*8

    %define verticies ebp-4*9
    %define indexes (ebp-4*9)-(4*4*8)

    mov eax, esp
    mov esp, indexes
    
    push 0
    push 1
    push 2
    push 0
    
    push 0
    push 2
    push 3
    push 0

    push 4
    push 5
    push 6
    push 0

    push 4
    push 6
    push 7
    push 0
    
    push 0
    push 4
    push 7
    push 0

    push 0
    push 7
    push 3
    push 0
    
    push 1
    push 5
    push 6
    push 0
    
    push 1
    push 6
    push 2
    push 0

    push 0
    push 1
    push 5
    push 0

    push 0
    push 5
    push 4
    push 0

    push 3
    push 2
    push 6
    push 0

    push 3
    push 6
    push 7
    push 0

    mov esp, eax

    vmovaps xmm0, [pos_x] ; loads pos 3d vector and size in xmm0
    ; xmm1: [s, s, s, s]
    vbroadcastss xmm1, dword [size]
    vsubps xmm2, xmm0, xmm1
    vmovaps [indexes], xmm2

    vaddps xmm2, xmm0, xmm1
    vmovaps [indexes - 4*4*6], xmm2
    ; ups because this isn't aligned after first push

    ; xmm0: [px, py, pz, s]
    ; xmm1: [s, s, s, s]
    vxorps xmm1, xmm1, [XMM_GV_SIGN_MASK]
    ; xmm1: [-s, s, s, s]

    vsubps xmm2, xmm0, xmm1
    vmovaps [indexes - 16*1], xmm2

    vaddps xmm2, xmm0, xmm1
    vmovaps [indexes - 16*7], xmm2

    ; xmm1:  0, 1, 2, 3
    ; xmm1: [5, 6, 7, 8]
    ; xmm1: [5, 7, 6, 6]
    ;        0, 2, 1, 1
    ;        0b00100101
    vshufps xmm1, xmm1, xmm1, 0b00001011
    ; xmm1: [-s, -s, s, s]

    vsubps xmm2, xmm0, xmm1
    vmovaps [indexes - 16*2], xmm2

    vaddps xmm2, xmm0, xmm1
    vmovaps [indexes - 16*4], xmm2

    vshufps xmm1, xmm1, xmm1, 0b10011011
    ; xmm1: [s, -s, s, s]

    vsubps xmm2, xmm0, xmm1
    vmovaps [indexes - 16*3], xmm2

    vaddps xmm2, xmm0, xmm1
    vmovaps [indexes - 16*5], xmm2

    xor ecx, ecx
make_cube_for_values_in_idx:
    cmp ecx, 12
    jge make_cube_for_values_in_idx_end

    imul ecx, 4
    vmovaps

    inc ecx
    jmp make_cube_for_values_in_idx

make_cube_for_values_in_idx_end:
    ret

parallel:
; ebx is initialized to core register

    enter
    push -1.4
    push 0.8
    push 0.0
    push 0.8
    push COL_MIRROR_0
    push COL_MIRROR_1
    push COL_MIRROR_2
    push 1
    call make_cube
    leave

    enter
    push 1.4
    push COL_LIGHT_0
    push COL_LIGHT_1
    push COL_LIGHT_2
    push 2
    call make_cube
    leave

    cli
    hlt
    jmp $


