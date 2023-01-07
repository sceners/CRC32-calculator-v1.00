;------------------------
; CRC32 Calculator v1.00
;    by FiNS//HTBTeam
;------------------------

.386
.model flat, stdcall  ;32 bit memory model
option casemap :none  ;case sensitive

include crc.inc

.code

start:

	invoke GetModuleHandle,NULL
	mov		hInstance,eax
	invoke DialogBoxParam,hInstance,dlgMain,NULL,addr DlgProc,NULL
	invoke ExitProcess,0

;########################################################################

InfoProc proc hWin:DWORD,uMsg:DWORD,idEvent:DWORD,dwTime:DWORD

    inc     infoPos
    .if infoPos>infoSize-60
        mov infoPos, 0
    .endif
    mov     eax, offset informacje
    add     eax, infoPos
    invoke lstrcpyn,addr informacje2,eax,60
    invoke SetDlgItemText,hWin,stcInfo,addr informacje2
    ret

InfoProc endp

CRC32 proc uses ebx ecx edx esi bufSize:DWORD,bufData:DWORD

    invoke SendMessage,hPgbCrc,PBM_SETPOS,0,0
    xor     eax, eax
    cdq
    dec     eax
    mov     ecx, bufSize
    mov     esi, bufData
    mov     ebx, ecx
    shr     ebx, 7 ;ebx=ebx/128
@@:
    mov     dl, byte ptr [esi]
    xor     dl, al
    shr     eax, 8
    xor     eax, dword ptr [crc32table + 4*edx]
    inc     esi
    dec     ecx
    je      exit
    dec     ebx
    jne     @B
    pusha
    invoke SendMessage,hPgbCrc,PBM_STEPIT,0,0
    popa
    mov     ebx, bufSize
    shr     ebx, 7
    jmp     @B
exit:
    not     eax
    push    eax
    invoke SendMessage,hPgbCrc,PBM_SETPOS,128,0
    pop     eax
    ret

CRC32 endp

DlgProc proc uses esi edi ebp ebx hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	mov		eax,uMsg
	.if eax==WM_INITDIALOG
        invoke SetTimer,hWin,321,120,InfoProc
        invoke GetDlgItem,hWin,pgbCrc
        mov     hPgbCrc, eax
        invoke SendMessage,eax,PBM_SETSTEP,1,0
        invoke SendMessage,hPgbCrc,PBM_SETRANGE,0,00800000h
        invoke LoadIcon,hInstance,icoSnow
        invoke SendMessage,hWin,WM_SETICON,ICON_BIG,eax
    .elseif eax==WM_DROPFILES
        invoke DragQueryFile,wParam,0,addr fileName,1024
        invoke SetDlgItemText,hWin,edtFile,addr fileName
    .elseif eax==WM_MOUSEMOVE
        .if wParam==MK_LBUTTON
            invoke ReleaseCapture
            invoke SendMessage,hWin,WM_SYSCOMMAND,SC_MOVE+2,0
        .endif
	.elseif eax==WM_COMMAND
        .if wParam==btnBrowse
            mov     ofnStruct.lStructSize, sizeof ofnStruct
            push    hWin
            pop     ofnStruct.hwndOwner
            mov     ofnStruct.lpstrFile, offset fileName
            mov     ofnStruct.nMaxFile, sizeof fileName
            mov     ofnStruct.Flags, OFN_FILEMUSTEXIST
            invoke GetOpenFileName,addr ofnStruct
            invoke SetDlgItemText,hWin,edtFile,addr fileName
        .elseif wParam==btnCalc
            invoke GetDlgItemText,hWin,edtFile,addr fileName,1024
            invoke CreateFile,addr fileName,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
            .if eax!=-1
                mov     hFile, eax
                invoke CreateFileMapping,eax,0,PAGE_READONLY,0,0,0
                mov     hFileMap, eax
                invoke MapViewOfFile,eax,FILE_MAP_READ,0,0,0
                mov     fileMap, eax
                invoke SetDlgItemText,hWin,stcInfo,addr pleaseWait
                invoke GetFileSize,hFile,0
                invoke CRC32,eax,fileMap
                invoke wsprintf,addr crcSum,addr crcSumForm,eax
                invoke SetDlgItemText,hWin,edtCrc,addr crcSum
                invoke UnmapViewOfFile,fileMap
                invoke CloseHandle,hFileMap
                invoke CloseHandle,hFile
            .else
                invoke MessageBox,hWin,addr openErrorTxt,addr openErrorCap,MB_ICONSTOP
            .endif
        .endif
	.elseif eax==WM_CLOSE
		invoke EndDialog,hWin,0
	.else
		mov		eax,FALSE
		ret
	.endif
	mov		eax,TRUE
	ret

DlgProc endp

end start
