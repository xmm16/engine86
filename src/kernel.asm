org 0x7e00
bits 16

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
    mov esp, 0x90000

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
    mov eax, 0x1000
    mul ebx
    mov esp, 0x90000
    sub esp, eax
    jmp parallel

make_triangle:

make_cube:
    %define make_cube_ARG_struc_addr eax
    %define make_cube_ARG_v_arr_addr edx
    %define make_cube_ARG_triangle_parameters esi
    ; also uses xmm0, xmm1, xmm2, ecx, edi

    vmovaps xmm0, [make_cube_ARG_struc_addr]
    ; xmm1: [s, s, s, s]
    vbroadcastss xmm1, dword [make_cube_ARG_struc_addr + CUBE.size]
    vsubps xmm2, xmm0, xmm1
    vmovaps [make_cube_ARG_v_arr_addr + 16*0], xmm2

    vaddps xmm2, xmm0, xmm1
    vmovaps [make_cube_ARG_v_arr_addr + 16*6], xmm2
    ; ups because this isn't aligned after first push

    ; xmm0: [px, py, pz, s]
    ; xmm1: [s, s, s, s]
    vxorps xmm1, xmm1, [XMM_GV_SIGN_MASK]
    ; xmm1: [-s, s, s, s]

    vsubps xmm2, xmm0, xmm1
    vmovaps [make_cube_ARG_v_arr_addr + 16*1], xmm2

    vaddps xmm2, xmm0, xmm1
    vmovaps [make_cube_ARG_v_arr_addr + 16*7], xmm2

    ; xmm1:  0, 1, 2, 3
    ; xmm1: [5, 6, 7, 8]
    ; xmm1: [5, 7, 6, 6]
    ;        0, 2, 1, 1
    ;        0b00100101
    vshufps xmm1, xmm1, xmm1, 0b00001011
    ; xmm1: [-s, -s, s, s]

    vsubps xmm2, xmm0, xmm1
    vmovaps [make_cube_ARG_v_arr_addr + 16*2], xmm2

    vaddps xmm2, xmm0, xmm1
    vmovaps [make_cube_ARG_v_arr_addr + 16*4], xmm2

    vshufps xmm1, xmm1, xmm1, 0b10011011
    ; xmm1: [s, -s, s, s]

    vsubps xmm2, xmm0, xmm1
    vmovaps [make_cube_ARG_v_arr_addr + 16*3], xmm2

    vaddps xmm2, xmm0, xmm1
    vmovaps [make_cube_ARG_v_arr_addr + 16*5], xmm2

    xor ecx, ecx
make_cube_for_values_in_idx:
    ; ecx + GLOBAL_MAKE_CUBE_INDEX + 4*0/1/2
    mov edi, [ecx + GLOBAL_MAKE_CUBE_INDEX + 4*0] ; i1
    mov edi, [edi*4 + make_cube_ARG_v_arr_addr]
    mov [make_cube_ARG_triangle_parameters], edi

    mov edi, [ecx + GLOBAL_MAKE_CUBE_INDEX + 4*1] ; i2
    mov edi, [edi*4 + make_cube_ARG_v_arr_addr]
    mov [make_cube_ARG_triangle_parameters + 4], edi

    mov edi, [ecx + GLOBAL_MAKE_CUBE_INDEX + 4*2] ; i3
    mov edi, [edi*4 + make_cube_ARG_v_arr_addr]
    mov [make_cube_ARG_triangle_parameters + 4*2], edi

    call make_triangle

    add ecx, 12
    cmp ecx, 144
    jl make_cube_for_values_in_idx

    ret

parallel:
    mov eax, 0xFEE00020
    mov ebx, [eax]
    shr ebx, 24
    lock inc dword [num_total_cores] ; atomics are fine to freely use until update loop

    %define WIDTH 1600
    %define HEIGHT 1052
    %define PIXEL_SIZE 3
    %define SAMPLES_PER_AXIS 3
    %define SAMPLES_PER_AXIS_SQ 9 ; SAMPLES_PER_AXIS squared
    %define MAX_DEPTH 2
    %define FOV 42.0
    %define EPSILON 0.00001
    %define CORE_NUM ebx

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

    cmp CORE_NUM, 0
    jmp root_setup_end


root_setup: ; before the first frame begins
    mov make_cube_ARG_struc_addr, cube_1
    mov make_cube_ARG_v_arr_addr, make_cube_v_1
    mov make_cube_ARG_triangle_parameters, make_cube_1_triangle_parameters
    call make_cube

    mov make_cube_ARG_struc_addr, cube_2
    mov make_cube_ARG_v_arr_addr, make_cube_v_2
    mov make_cube_ARG_triangle_parameters, make_cube_2_triangle_parameters
    call make_cube
    
root_setup_end:
    mov edi, [lfb_addr]

    mov byte [edi], 0x00
    mov byte [edi+1], 0x00
    mov byte [edi+2], 0xFF
    mov edx, ebx
    imul edx, 3
    add edi, edx
    mov edx, 1600*3
    imul edx, ebx
    add edi, edx

    mov byte [edi], 0x00
    mov byte [edi+1], 0x00
    mov byte [edi+2], 0xFF

    cli
    hlt
    jmp $


section .data
align 4
lfb_addr:  dd 0
mode_info: times 256 db 0
num_total_cores: dd 0
XMM_GV_SIGN_MASK: dd 0x80000000 ; 10000000000000000000000000000000000000000000000
GLOBAL_MAKE_CUBE_INDEX: 
    dd 0, 1, 2
    dd 0, 2, 3
    dd 4, 5, 6
    dd 4, 6, 7
    dd 0, 4, 7
    dd 0, 7, 3
    dd 1, 5, 6
    dd 1, 6, 2
    dd 0, 1, 5
    dd 0, 5, 4
    dd 3, 2, 6
    dd 3, 6, 7

struc CUBE
  .pos_x: resb 4
  .pos_y: resb 4
  .pos_z: resb 4
  
  .size: resb 4
  
  .color_x: resb 4
  .color_y: resb 4
  .color_z: resb 4

  .mat: resb 4
endstruc

align 32 ; ymm registers
cube_1:
  istruc CUBE
    at .pos_x, dd -1.4
    at .pos_y, dd 0.8
    at .pos_z, dd 0.0
    
    at .size, dd 0.8

    at .color_x, dd COL_MIRROR_0
    at .color_y, dd COL_MIRROR_1
    at .color_z, dd COL_MIRROR_2

    at .mat, dd 1
  iend

align 32
cube_2:
  istruc CUBE
    at .pos_x, dd 1.4
    at .pos_y, dd 0.8
    at .pos_z, dd 0.0
    
    at .size, dd 0.8

    at .color_x, dd COL_LIGHT_0
    at .color_y, dd COL_LIGHT_1
    at .color_z, dd COL_LIGHT_2

    at .mat, dd 2
  iend

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

align 32
make_cube_v_1: resb 4*4*8
make_cube_v_2: resb 4*4*8

make_cube_1_triangle_parameters: resb 4*3*2 + 4 ; 28 in total, not 32 aligned anymore
make_cube_2_triangle_parameters: resb 4*3*2 + 4 ; 28 in total, not 32 aligned anymore
