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
num_cores: dd 0
state: dd 0 ; should be equal to num_cores before switching modes both ways, from calc to graph or from graph to calc

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
    mov eax, 100*50 + 4 + 4 + 3000  ; max size of the stack for the core, 100*MAX_NUM_TRIANGLES + SIZE_OF_NUMBER_OF_TRIANGLES + SIZE_OF_CORE_ID + SIZE_OF_WORKPLACE all in bytes
    mul ebx ; ebx stays the same
    mov esp, 0x9FFF0 ; stack begin!
    sub esp, eax
    jmp parallel

graphics: ; each core jumps to this in between updating, including inactive for calculation cores, so divide by the num_cores

parallel:
; ebx is initialized to core register
    mov ebp, esp
    lock inc num_cores 

    %define CORE_ID ebp-4
    push ebx

    %define NUM_TRIANGLES ebp-8
    push ______________ ; put number of triangles there

    and esp, -64 ; align to 64 bytes
    ; align to 64 bytes after each triangle too

    cmp ebx, 0
    je core_0


; ok so basically here we define objects owned by cores
; you don't have to use all cores
; in each core, you have to use graphics

core_0:
    ; define objects of triangles here

    cli
    hlt
    jmp $


