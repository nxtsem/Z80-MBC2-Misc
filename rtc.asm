;  RTC.ASM   Print Real Time Clock  May 9,2024
;  YEAR= YEAR + 2000
;  IF TEMP >= 128 THEN TEMP = TEMP - 256 : REM Two complement correction
;  
; CONSTANTS
TAB_WIDTH         .equ  8
CTRLC             .equ  3      ; ^C
BACKSPACE         .equ  8      ; was $7F -mod
TAB               .equ  9
EOL               .equ  13     ;  ie. CR
ESC               .equ  27       
BDOS              .equ  5
FCB               .equ  005CH  ; We use the standard default FCB
DMA               .equ  0080H  ; Standard DMA area
         
; Z80-MBC2 IOS (I/O Subsystem) equates
EXC_WR_OPCD       .equ  $00    ; Addr of EXECUTE WRITE OPCODE write port
EXC_RD_OPCD       .equ  $00    ; Addr of EXECUTE READ OPCODE read port
STO_OPCD          .equ  $01    ; Addr of STORE OPCODE write port
SERIAL_RX         .equ  $01    ; Addr of SERIAL RX read port
SERTX_OPC         .equ  $01    ; SERIAL TX opcode
SELDISK_OPC       .equ  $09    ; SELDISK opcode
SELTRCK_OPC       .equ  $0A    ; SELTRACK opcode
SELSECT_OPC       .equ  $0B    ; SELSECT opcode
WRTSECT_OPC       .equ  $0C    ; WRITESECT opcode
SETSPP_OPC        .equ  $11    ; SETSPP opcode
WRSPP_OPC         .equ  $12    ; WRSPP opcoce
SYSFLAG_OPC       .equ  $83    ; SYSFLAG opcode
ERRDSK_OPC        .equ  $85    ; ERRDISK opcode
RDSECT_OPC        .equ  $86    ; READSECT opcode
SDMOUNT_OPC       .equ  $87    ; SDMOUNT opcode
GETSPP_OPC        .equ  $8A    ; GETSPP opcode
SPPRDY            .equ  $C9    ; SPP status printer ready pattern (11001001)
DATETIM_OPC       .equ  $84    ; DATETIME opcode

BDOS_Cons_Input   .equ  1      ; C=01, A=char in
BDOS_Cons_Output  .equ  2      ; C=02, E=char out
BDOS_Dir_Cons_IO  .equ  6      ; C=06, E=char in/out
BDOS_Print_String .equ  9      ; C=09, DE=Str Addr, ends with $ 
BDOS_Rd_Cons_Buf  .equ  10     ; C=0A, DE=Buf Addr, Byte0=bufsize,Byte1=char read
BDOS_Open_File    .equ  15     ; C=0F, 255 = file not found
BDOS_Close_File   .equ  16     ; C=10, 255 = file not found
BDOS_Search_First .equ  17     ; C=11  255 = file not found
BDOS_Delete_File  .equ  19     ; C=13, 255 = file not found
BDOS_Read_Seq     .equ  20     ; C=14, 0 = OK
BDOS_Write_Seq    .equ  21     ; C=15, 0 = OK
BDOS_Make_File    .equ  22     ; C=16, 255 = Disk Full
BDOS_Rename_File  .equ  23     ; C=17, 255 = file not found
BDOS_Set_DMA_Addr .equ  26     ; C=1A

; Z80-MBC2 BIOS equate table                                                             
BIOS_BOOT         .equ  $E800  ; COLD START
BIOS_WBOOT        .equ  $E803  ; WARM START
BIOS_CONST        .equ  $E806  ; CONSOLE STATUS
BIOS_CONIN        .equ  $E809  ; CONSOLE CHARACTER IN
BIOS_CONOUT       .equ  $E80C  ; CONSOLE CHARACTER OUT
BIOS_LIST         .equ  $E80F  ; LIST CHARACTER OUT
BIOS_PUNCH        .equ  $E812  ; PUNCH CHARACTER OUT
BIOS_READER       .equ  $E815  ; READER CHARACTER IN
BIOS_HOME         .equ  $E818  ; MOVE HEAD TO HOME POSITION
BIOS_SELDSK       .equ  $E81B  ; SELECT DISK
BIOS_SETTRK       .equ  $E81E  ; SET TRACK NUMBER
BIOS_SETSEC       .equ  $E821  ; SET SECTOR NUMBER
BIOS_SETDMA       .equ  $E824  ; SET DMA ADDRESS
BIOS_READ         .equ  $E827  ; READ DISK
BIOS_WRITE        .equ  $E82A  ; WRITE DISK
BIOS_PRSTAT       .equ  $E82D  ; RETURN LIST STATUS
BIOS_SECTRN       .equ  $E830  ; SECTOR TRANSLATE

    .org $0100

entry:  ld sp, stacktop        ; Set the stack to point to our local stack
                                                                      
; NOTE: If the RTC is not present, IOS will give all 0s bytes.              
    ld  a, DATETIM_OPC         ; Select DATETIME opcode (IOS)
    out (STO_OPCD), a          
    in  a, (EXC_RD_OPCD)       ; Read RTC seconds
    ld  (RTCSEC), a            ; Store it into date/time seconds
    in  a, (EXC_RD_OPCD)       ; Read RTC minutes
    ld  (RTCMIN), a            ; Store it into date/time minutes
    in  a, (EXC_RD_OPCD)       ; Read RTC hours
    ld  (RTCHR), a             ; Store it into date/time hours
    in  a, (EXC_RD_OPCD)       ; Read RTC day
    ld  (RTCDAY), a            ; Store it into date/time day
    in  a, (EXC_RD_OPCD)       ; Read RTC month
    ld  (RTCMO), a             ; Store it into date/time month
    in  a, (EXC_RD_OPCD)       ; Read RTC year
    ld  (RTCYR), a             ; Store it into date/time year
    in  a, (EXC_RD_OPCD)       ; Read RTC temperature
    ld  (RTCTEMP), a           ; Store it into date/time vector

	

GT80:
    ld de, Timemsg 
    ld c,  BDOS_Print_String
	call BDOS 
	ld a, (RTCHR)
    call print_a_as_decimal
    ld a, ':'
    call print_a
    ld a, (RTCMIN)
    call print_a_as_decimal
    ld a, ':'
    call print_a	
    ld a, (RTCSEC)
    call print_a_as_decimal	
	
    ld de, Datemsg 
    ld c,  BDOS_Print_String
    call BDOS 
    ld a, (RTCDAY)
    call print_a_as_decimal
    ld a, ':'
    call print_a
    ld a, (RTCMO)
    call print_a_as_decimal
    ld a, ':'
    call print_a
	ld a, '2'
    call print_a
	ld a, '0'
    call print_a	
    ld a, (RTCYR)
    call print_a_as_decimal
 
    ld a, (RTCTEMP)
    sub $80
	jr NC, NTemp
    ld de, PTmpmsg 
	jr Prnmsg
Ntemp:	
    ld (RTCTEMP),a
    ld de, NTmpmsg
Prnmsg:   
    ld c,  BDOS_Print_String
    call BDOS
	
    ld a, (RTCTEMP)
    call print_a_as_decimal
 	ld a, 'C'
    call print_a	
	
    ld de, Endmsg 
    ld c,  BDOS_Print_String
    call BDOS        
    jp  0           ; Warm Start
 

Timemsg: .db "Time: ",'$'
Datemsg: .db 13,10,"Date: ",'$' 
PTmpmsg: .db 13,10,"Temp: ",'$'
NTmpmsg: .db 13,10,"Temp:-",'$'
Endmsg:  .db 13,10,'$'
 
; Prints "a" to the screen
print_a:
    push hl
    push bc
    push de
	ld e,a
    ld c, BDOS_Dir_Cons_IO
	call BDOS
    pop de
    pop bc
    pop hl
    ret 
 
; Prints a number (in a) from 0 to 255 in decimal
print_a_as_decimal:
    ld c, 0               ; c tells us if we have started printing digits
    ld b, a
    cp 100
    jr c, print_a_as_decimal_tens
    cp 200
    jr c, print_a_as_decimal_100
    ld a, '2'
    call print_a
    ld a, b
    sub 200
    jr print_a_as_decimal_101
print_a_as_decimal_100:
    ld a, '1'
    call print_a
    ld a, b
    sub 100
print_a_as_decimal_101:
    ld c, 1                     ; Yes, we have started printing digits
print_a_as_decimal_tens:
    ld b, 0
print_a_as_decimal_tens1:
    cp 10
    jr c, print_a_as_decimal_units
    sub 10
    inc b
    jr print_a_as_decimal_tens1
print_a_as_decimal_units:
    ld d, a
    ld a, b
    cp 0
    jr nz, print_a_as_decimal_show_tens
    ld a, c
    cp 0
    jr z, print_a_as_decimal_units1
print_a_as_decimal_show_tens:
    add a, '0'
    call print_a
print_a_as_decimal_units1:
    ld a, '0'
    add a, d
    call print_a
    ret
 
; variables

RTCDAY:  .db 0     ; day  (1..31)
RTCMO:   .db 0     ; month  (1..12)
RTCYR:   .db 0     ; year    (year = year + 2000)
RTCHR:   .db 0     ; hours   (0..23)
RTCMIN:  .db 0     ; minutes (0..59)
RTCSEC:  .db 0     ; seconds (0..59)
RTCTEMP: .db 0     ; temp (if temp >= 128 then temp = temp -256) 
YEAR:    .dw 0

stack   .db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 
stacktop         .db 0 
end_of_code      .db 0     

        .END
