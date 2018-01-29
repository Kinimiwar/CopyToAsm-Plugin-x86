;=====================================================================================
; x64dbg plugin SDK for Masm - fearless 2016 - www.LetTheLight.in
;
; CopyToAsm.asm
;
;-------------------------------------------------------------------------------------

.686
.MMX
.XMM
.model flat,stdcall
option casemap:none

DEBUG32 EQU 1

IFDEF DEBUG32
    PRESERVEXMMREGS equ 1
    includelib M:\Masm32\lib\Debug32.lib
    DBG32LIB equ 1
    DEBUGEXE textequ <'M:\Masm32\DbgWin.exe'>
    include M:\Masm32\include\debug32.inc
ENDIF

Include x64dbgpluginsdk.inc               ; Main x64dbg Plugin SDK for your program, and prototypes for the main exports 

include x64dbgpluginsdk_x86.inc
includelib x64dbgpluginsdk_x86.lib

Include CopyToAsm.inc ; plugin's include file

;=====================================================================================


.CONST
PLUGIN_VERSION      EQU 1

.DATA
PLUGIN_NAME         DB "CopyToAsm x86",0

.DATA?
;-------------------------------------------------------------------------------------
; GLOBAL Plugin SDK variables
;-------------------------------------------------------------------------------------
PUBLIC              pluginHandle
PUBLIC              hwndDlg
PUBLIC              hMenu
PUBLIC              hMenuDisasm
PUBLIC              hMenuDump
PUBLIC              hMenuStack

pluginHandle        DD ?
hwndDlg             DD ?
hMenu               DD ?
hMenuDisasm         DD ?
hMenuDump           DD ?
hMenuStack          DD ?
;-------------------------------------------------------------------------------------


.CODE

;=====================================================================================
; Main entry function for a DLL file  - required.
;-------------------------------------------------------------------------------------
DllMain PROC hinstDLL:HINSTANCE, fdwReason:DWORD, lpvReserved:DWORD
    .IF fdwReason == DLL_PROCESS_ATTACH
        mov eax, hinstDLL
        mov hInstance, eax
    .ENDIF
    mov eax,TRUE
    ret
DllMain ENDP


;=====================================================================================
; pluginit - Called by debugger when plugin.dp32 is loaded - needs to be EXPORTED
; 
; Arguments: initStruct - a pointer to a PLUG_INITSTRUCT structure
;
; Notes:     you must fill in the pluginVersion, sdkVersion and pluginName members. 
;            The pluginHandle is obtained from the same structure - it may be needed in
;            other function calls.
;
;            you can call your own setup routine from within this function to setup 
;            menus and commands, and pass the initStruct parameter to this function.
;
;-------------------------------------------------------------------------------------
pluginit PROC C PUBLIC USES EBX initStruct:DWORD
    mov ebx, initStruct

    ; Fill in required information of initStruct, which is a pointer to a PLUG_INITSTRUCT structure
    mov eax, PLUGIN_VERSION
    mov [ebx].PLUG_INITSTRUCT.pluginVersion, eax
    mov eax, PLUG_SDKVERSION
    mov [ebx].PLUG_INITSTRUCT.sdkVersion, eax
    Invoke lstrcpy, Addr [ebx].PLUG_INITSTRUCT.pluginName, Addr PLUGIN_NAME
    
    mov ebx, initStruct
    mov eax, [ebx].PLUG_INITSTRUCT.pluginHandle
    mov pluginHandle, eax
    
    ; Do any other initialization here



	mov eax, TRUE
	ret
pluginit ENDP


;=====================================================================================
; plugstop - Called by debugger when the plugin.dp32 is unloaded - needs to be EXPORTED
;
; Arguments: none
; 
; Notes:     perform cleanup operations here, clearing menus and other housekeeping
;
;-------------------------------------------------------------------------------------
plugstop PROC C PUBLIC 
    
    ; remove any menus, unregister any callbacks etc
    Invoke _plugin_menuclear, hMenu
    Invoke GuiAddLogMessage, Addr szCopyToAsmUnloaded
    
    mov eax, TRUE
    ret
plugstop ENDP


;=====================================================================================
; plugsetup - Called by debugger to initialize your plugins setup - needs to be EXPORTED
;
; Arguments: setupStruct - a pointer to a PLUG_SETUPSTRUCT structure
; 
; Notes:     setupStruct contains useful handles for use within x64dbg, mainly Qt 
;            menu handles (which are not supported with win32 api) and the main window
;            handle with this information you can add your own menus and menu items 
;            to an existing menu, or one of the predefined supported right click 
;            context menus: hMenuDisam, hMenuDump & hMenuStack
;            
;            plugsetup is called after pluginit. 
;-------------------------------------------------------------------------------------
plugsetup PROC C PUBLIC USES EBX setupStruct:DWORD
    LOCAL hIconData:ICONDATA
    
    mov ebx, setupStruct

    ; Extract handles from setupStruct which is a pointer to a PLUG_SETUPSTRUCT structure  
    mov eax, [ebx].PLUG_SETUPSTRUCT.hwndDlg
    mov hwndDlg, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenu
    mov hMenu, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuDisasm
    mov hMenuDisasm, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuDump
    mov hMenuDump, eax
    mov eax, [ebx].PLUG_SETUPSTRUCT.hMenuStack
    mov hMenuStack, eax
    
    ; Do any setup here: add menus, menu items, callback and commands etc

    Invoke _plugin_menuaddentry, hMenu, MENU_COPYTOASM_CLPB1, Addr szCopyToAsmMenuClip    
    Invoke _plugin_menuaddentry, hMenuDisasm, MENU_COPYTOASM_CLPB2, Addr szCopyToAsmMenuClip
    
    Invoke _plugin_menuaddentry, hMenu, MENU_COPYTOASM_REFV1, Addr szCopyToAsmMenuRefv    
    Invoke _plugin_menuaddentry, hMenuDisasm, MENU_COPYTOASM_REFV2, Addr szCopyToAsmMenuRefv    

    Invoke CTALoadMenuIcon, IMG_COPYTOASM_MAIN, Addr hIconData
    .IF eax == TRUE
        Invoke _plugin_menuseticon, hMenu, Addr hIconData
        Invoke _plugin_menuseticon, hMenuDisasm, Addr hIconData
    .ENDIF

    Invoke CTALoadMenuIcon, IMG_COPYTOASM_CLPB, Addr hIconData
    .IF eax == TRUE
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_COPYTOASM_CLPB1, Addr hIconData
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_COPYTOASM_CLPB2, Addr hIconData
    .ENDIF
    
    Invoke CTALoadMenuIcon, IMG_COPYTOASM_REFV, Addr hIconData
    .IF eax == TRUE
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_COPYTOASM_REFV1, Addr hIconData
        Invoke _plugin_menuentryseticon, pluginHandle, MENU_COPYTOASM_REFV2, Addr hIconData
    .ENDIF

    Invoke GuiAddLogMessage, Addr szCopyToAsmInfo
    Invoke GuiGetWindowHandle
    mov hwndDlg, eax   
        
    ret
plugsetup ENDP


;=====================================================================================
; CBMENUENTRY - Called by debugger when a menu item is clicked - needs to be EXPORTED
;
; Arguments: cbType
;            cbInfo - a pointer to a PLUG_CB_MENUENTRY structure. The hEntry contains 
;            the resource id of menu item identifiers
;  
; Notes:     hEntry can be used to determine if the user has clicked on your plugins
;            menu item(s) and to do something in response to it.
;            Needs to be PROC C type procedure call to be compatible with debugger
;-------------------------------------------------------------------------------------
CBMENUENTRY PROC C PUBLIC USES EBX cbType:DWORD, cbInfo:DWORD
    mov ebx, cbInfo
    mov eax, [ebx].PLUG_CB_MENUENTRY.hEntry
    
    .IF eax == MENU_COPYTOASM_CLPB1 || eax == MENU_COPYTOASM_CLPB2
       Invoke DbgIsDebugging
        .IF eax == FALSE
            Invoke GuiAddStatusBarMessage, Addr szDebuggingRequired
            Invoke GuiAddLogMessage, Addr szDebuggingRequired
        .ELSE
            Invoke DoCopyToAsm, 0 ; clipboard
        .ENDIF
        
    .ELSEIF eax == MENU_COPYTOASM_REFV1 || MENU_COPYTOASM_REFV2
       Invoke DbgIsDebugging
        .IF eax == FALSE
            Invoke GuiAddStatusBarMessage, Addr szDebuggingRequired
            Invoke GuiAddLogMessage, Addr szDebuggingRequired
        .ELSE
            Invoke DoCopyToAsm, 1 ; refview
        .ENDIF
        
    .ENDIF
    
    mov eax, TRUE
    ret

CBMENUENTRY ENDP


;=====================================================================================
; CTALoadMenuIcon - Loads RT_RCDATA png resource and assigns it to ICONDATA
; Returns TRUE in eax if succesful or FALSE otherwise.
;-------------------------------------------------------------------------------------
CTALoadMenuIcon PROC USES EBX dwImageResourceID:DWORD, lpIconData:DWORD
    LOCAL hRes:DWORD
    
    ; Load image for our menu item
    Invoke FindResource, hInstance, dwImageResourceID, RT_RCDATA ; load png image as raw data
    .IF eax != NULL
        mov hRes, eax
        Invoke SizeofResource, hInstance, hRes
        .IF eax != 0
            mov ebx, lpIconData
            mov [ebx].ICONDATA.size_, eax
            Invoke LoadResource, hInstance, hRes
            .IF eax != NULL
                Invoke LockResource, eax
                .IF eax != NULL
                    mov ebx, lpIconData
                    mov [ebx].ICONDATA.data, eax
                    mov eax, TRUE
                .ELSE
                    ;PrintText 'Failed to lock resource'
                    mov eax, FALSE
                .ENDIF
            .ELSE
                ;PrintText 'Failed to load resource'
                mov eax, FALSE
            .ENDIF
        .ELSE
            ;PrintText 'Failed to get resource size'
            mov eax, FALSE
        .ENDIF
    .ELSE
        ;PrintText 'Failed to find resource'
        mov eax, FALSE
    .ENDIF    
    ret

CTALoadMenuIcon ENDP


;-------------------------------------------------------------------------------------
; Copies selected disassembly range to clipboard and formats as masm style code
; fixes jmps and labels relative to each other, removes segments and 0x from instructions
;-------------------------------------------------------------------------------------
DoCopyToAsm PROC USES EBX ECX dwOutput:DWORD
    LOCAL bii:BASIC_INSTRUCTION_INFO ; basic 
    LOCAL sel:SELECTIONDATA
    LOCAL sellength:DWORD
    LOCAL dwStartAddress:DWORD
    LOCAL dwFinishAddress:DWORD
    LOCAL dwCurrentAddress:DWORD
    LOCAL JmpDestination:DWORD
    LOCAL ptrClipboardData:DWORD
    LOCAL LenClipData:DWORD
    LOCAL pClipData:DWORD
    LOCAL hClipData:DWORD
    LOCAL bOutsideRange:DWORD
    LOCAL dwCTALIndex:DWORD
    
    
    Invoke DbgIsDebugging
    .IF eax == FALSE
        Invoke GuiAddLogMessage, Addr szDebuggingRequired
        ret
    .ENDIF
    Invoke GuiAddStatusBarMessage, Addr szStartCopyToAsm


    ;----------------------------------
    ; Get selection information
    ;----------------------------------
    Invoke GuiSelectionGet, GUI_DISASSEMBLY, Addr sel
    mov eax, sel.finish
    mov dwFinishAddress, eax
    mov ebx, sel.start
    mov dwStartAddress, ebx
    sub eax, ebx
    mov sellength, eax
    mov dwCTALIndex, 0

    ;----------------------------------
    ; Get some info for user
    ;----------------------------------
    Invoke ModNameFromAddr, sel.start, Addr szModuleName, TRUE
    Invoke ModBaseFromAddr, sel.start
    mov ModBase, eax


    ;----------------------------------
    ; 1st pass build jmp destination array
    ;----------------------------------
    Invoke CTABuildJmpTable, dwStartAddress, dwFinishAddress
    .IF eax == FALSE
        ret
    .ENDIF

    .IF dwOutput == 0 ; clipboard
        ;----------------------------------
        ; Alloc space for clipboard data
        ;----------------------------------
        .IF CLIPDATASIZE != 0
            Invoke szLen, Addr szModuleName
            add eax, 64d; "; Source: "+CRLF + CRLF + (base 0x12345678 - 12345678)
            add CLIPDATASIZE, eax
    
            Invoke GlobalAlloc, GMEM_FIXED + GMEM_ZEROINIT, CLIPDATASIZE
            .IF eax == NULL
                Invoke GuiAddStatusBarMessage, Addr szErrorClipboardData
                mov eax, FALSE
                ret
            .ENDIF
            mov ptrClipboardData, eax    
            Invoke OpenClipboard, 0
            .IF eax == 0
                Invoke GlobalFree, ptrClipboardData
                Invoke GuiAddStatusBarMessage, Addr szErrorClipboardData
                mov eax, FALSE
                ret
            .ENDIF
            Invoke EmptyClipboard
        .ELSE
            Invoke GuiAddStatusBarMessage, Addr szErrorClipboardData
        .ENDIF
    
    
        ;----------------------------------
        ; Start : Module Name and Base
        ;----------------------------------
        Invoke szCatStr, ptrClipboardData, Addr szModuleSource
        Invoke szCatStr, ptrClipboardData, Addr szModuleName
        Invoke dw2hex, ModBase, Addr szValueString
        Invoke szCatStr, ptrClipboardData, Addr szModBase
        Invoke szCatStr, ptrClipboardData, Addr szValueString
        Invoke utoa_ex, ModBase, Addr szValueString
        Invoke szCatStr, ptrClipboardData, Addr szModBaseHex
        Invoke szCatStr, ptrClipboardData, Addr szValueString
        Invoke szCatStr, ptrClipboardData, Addr szRightBracket
        Invoke szCatStr, ptrClipboardData, Addr szCRLF
        Invoke szCatStr, ptrClipboardData, Addr szCRLF
    
    
        ;----------------------------------
        ; Labels Before
        ;----------------------------------
        Invoke CTAOutputLabelsOutsideRangeBefore, dwStartAddress, ptrClipboardData
    
    
        ;----------------------------------
        ; Start Information
        ;----------------------------------
        Invoke szCatStr, ptrClipboardData, Addr szCommentSelStart
        Invoke dw2hex, dwStartAddress, Addr szValueString
        Invoke szCatStr, ptrClipboardData, Addr szHex
        Invoke szCatStr, ptrClipboardData, Addr szValueString
        Invoke szCatStr, ptrClipboardData, Addr szOffsetLeftBracket
        Invoke utoa_ex, dwStartAddress, Addr szValueString
        Invoke szCatStr, ptrClipboardData, Addr szValueString
        Invoke szCatStr, ptrClipboardData, Addr szRightBracket
        Invoke szCatStr, ptrClipboardData, Addr szCRLF
        
    .ELSE ; output to reference view

        Invoke CTA_AddColumnsToRefView, dwStartAddress, dwFinishAddress
        
        ;----------------------------------
        ; Labels Before
        ;----------------------------------        
        Invoke CTARefViewLabelsOutsideRangeBefore, dwStartAddress, dwCTALIndex
        mov dwCTALIndex, eax

    .ENDIF


    ;----------------------------------
    ; Start main loop processing selection
    ;----------------------------------
    mov eax, dwStartAddress
    mov dwCurrentAddress, eax
    .WHILE eax <= dwFinishAddress
        
        Invoke CTAAddressInJmpTable, dwCurrentAddress
        .IF eax != 0
            Invoke CTALabelFromJmpEntry, eax, Addr szLabelX
            .IF dwOutput == 0 ; output to clipboard
                Invoke szCatStr, ptrClipboardData, Addr szCRLF
                Invoke szCatStr, ptrClipboardData, Addr szLabelX
                Invoke szCatStr, ptrClipboardData, Addr szCRLF
            .ELSE ; output to reference view
                Invoke CTA_AddRowToRefView, dwCTALIndex, Addr szLabelX
                inc dwCTALIndex
            .ENDIF
        .ENDIF
        
        Invoke DbgDisasmFastAt, dwCurrentAddress, Addr bii
        movzx eax, byte ptr bii.call_
        movzx ebx, byte ptr bii.branch
        
        .IF eax == 1 && ebx == 1 ; we have call statement
            Invoke GuiGetDisassembly, dwCurrentAddress, Addr szDisasmText
            Invoke Strip_x64dbg_calls, Addr szDisasmText, Addr szCALLFunction
            Invoke szCopy, Addr szCall, Addr szFormattedDisasmText
            Invoke szCatStr, Addr szFormattedDisasmText, Addr szCALLFunction
        
        .ELSEIF eax == 0 && ebx == 1 ; jumps
            Invoke DbgGetBranchDestination, dwCurrentAddress
            mov JmpDestination, eax
            
            mov eax, dwStartAddress
            mov ebx, dwFinishAddress
            .IF JmpDestination < eax || JmpDestination > ebx
                mov bOutsideRange, TRUE
            .ELSE
                mov bOutsideRange, FALSE
            .ENDIF
            
            Invoke GuiGetDisassembly, dwCurrentAddress, Addr szDisasmText
            Invoke CTAAddressInJmpTable, JmpDestination
            .IF eax != 0
                Invoke CTAJmpLabelFromJmpEntry, eax, bOutsideRange, Addr szDisasmText, Addr szFormattedDisasmText
            .ELSE
                PrintText 'jmp destination not in CTAAddressInJmpTable!'
            .ENDIF

        .ELSE ; normal non jump or call instructions
            Invoke GuiGetDisassembly, dwCurrentAddress, Addr szDisasmText
            Invoke Strip_x64dbg_segments, Addr szDisasmText, Addr szFormattedDisasmText

            mov eax, bii.type_
            .IF eax == TYPE_VALUE
                Invoke szCatStr, Addr szFormattedDisasmText, Addr szMasmHexH
            .ELSEIF eax == TYPE_MEMORY || eax == (TYPE_VALUE or TYPE_MEMORY)
                Invoke szCopy, Addr szFormattedDisasmText, Addr szDisasmText 
                Invoke CTAMnemonicToMasmHex, Addr szDisasmText, Addr szFormattedDisasmText, Addr bii
            .ENDIF

        .ENDIF
        
        .IF dwOutput == 0 ; output to clipboard
            Invoke szCatStr, ptrClipboardData, Addr szFormattedDisasmText
            Invoke szCatStr, ptrClipboardData, Addr szCRLF
        .ELSE ; output to reference view
            Invoke CTA_AddRowToRefView, dwCTALIndex, Addr szFormattedDisasmText
        .ENDIF
        
        inc dwCTALIndex
        
        mov eax, bii.size_ 
        add dwCurrentAddress, eax        
        mov eax, dwCurrentAddress
    .ENDW    
    ;----------------------------------
    ; End main loop
    ;----------------------------------


    .IF dwOutput == 0 ; output to clipboard
        ;----------------------------------
        ; Finish Information
        ;----------------------------------
        Invoke szCatStr, ptrClipboardData, Addr szCommentSelFinish
        Invoke dw2hex, dwFinishAddress, Addr szValueString
        Invoke szCatStr, ptrClipboardData, Addr szHex
        Invoke szCatStr, ptrClipboardData, Addr szValueString
        Invoke szCatStr, ptrClipboardData, Addr szOffsetLeftBracket
        Invoke utoa_ex, dwFinishAddress, Addr szValueString
        Invoke szCatStr, ptrClipboardData, Addr szValueString
        Invoke szCatStr, ptrClipboardData, Addr szRightBracket
        Invoke szCatStr, ptrClipboardData, Addr szCRLF
        ;Invoke szCatStr, ptrClipboardData, Addr szCRLF
    
    
        ;----------------------------------
        ; Labels After
        ;----------------------------------
        Invoke CTAOutputLabelsOutsideRangeAfter, dwFinishAddress, ptrClipboardData
        
    .ELSE

        ;----------------------------------
        ; Labels After
        ;----------------------------------    
        Invoke CTARefViewLabelsOutsideRangeAfter, dwFinishAddress, dwCTALIndex
        mov dwCTALIndex, eax
    
    .ENDIF


    Invoke CTAClearJmpTable ; free jmp table


    .IF dwOutput == 0 ; output to clipboard
        ;----------------------------------
        ; set clipboard data
        ;----------------------------------
        Invoke szLen, ptrClipboardData
        .IF eax != 0
            mov LenClipData, eax
            inc eax
            Invoke GlobalAlloc, GMEM_MOVEABLE, eax
            .IF eax == NULL
                Invoke GlobalFree, ptrClipboardData
                Invoke CloseClipboard
                ret
            .ENDIF
            mov hClipData, eax
            
            Invoke GlobalLock, hClipData
            .IF eax == NULL
                Invoke GlobalFree, ptrClipboardData
                Invoke GlobalFree, hClipData
                Invoke CloseClipboard
                ret
            .ENDIF
            mov pClipData, eax
            mov eax, LenClipData
            Invoke RtlMoveMemory, pClipData, ptrClipboardData, eax
            
            Invoke GlobalUnlock, hClipData 
            invoke SetClipboardData, CF_TEXT, hClipData
        
            Invoke CloseClipboard
            Invoke GlobalFree, ptrClipboardData
        .ENDIF
    
        ;PrintText 'Finished'
        Invoke GuiAddStatusBarMessage, Addr szFinishCopyToAsm
        
    .ELSE
    
        Invoke GuiAddStatusBarMessage, Addr szFinishCopyToAsmRefView
        Invoke GuiReferenceSetSingleSelection, 0, TRUE
        Invoke GuiReferenceReloadData
    .ENDIF
    ret

DoCopyToAsm ENDP


;-------------------------------------------------------------------------------------
; 1st pass of selection, build an array of jmp destinations
; estimates size required based on selection size (bytes) / 2 (jmp near = 2 bytes long)
; = no of entries (max safe estimate) * size jmptable_entry struct
; also roughly calcs the size of clipboard data required
;-------------------------------------------------------------------------------------
CTABuildJmpTable PROC USES EBX dwStartAddress:DWORD, dwFinishAddress:DWORD
    LOCAL bii:BASIC_INSTRUCTION_INFO ; basic 
    LOCAL dwJmpTableSize:DWORD
    LOCAL dwCurrentAddress:DWORD
    LOCAL JmpDestination:DWORD
    LOCAL nJmpEntry:DWORD
    LOCAL ptrJmpEntry:DWORD

    
    ;PrintText 'CTABuildJmpTable'
    
    mov CLIPDATASIZE, 0
    
    mov eax, dwFinishAddress
    mov ebx, dwStartAddress
    sub eax, ebx
    .IF sdword ptr eax < 0
        neg eax
    .ENDIF
    shr eax, 1 ; div by 2
    mov JMPTABLE_ENTRIES_MAX, eax
    mov ebx, SIZEOF JMPTABLE_ENTRY
    mul ebx
    mov dwJmpTableSize, eax
    
    Invoke GlobalAlloc, GMEM_FIXED + GMEM_ZEROINIT, dwJmpTableSize
    .IF eax == NULL
        Invoke GuiAddStatusBarMessage, Addr szErrorAllocMemJmpTable
        mov eax, FALSE
        ret
    .ENDIF
    mov JMPTABLE, eax
    mov ptrJmpEntry, eax
    mov nJmpEntry, 0

    mov eax, dwStartAddress
    mov dwCurrentAddress, eax


    .WHILE eax <= dwFinishAddress
        Invoke DbgDisasmFastAt, dwCurrentAddress, Addr bii
        movzx eax, byte ptr bii.call_
        movzx ebx, byte ptr bii.branch
        
        .IF eax ==0 && ebx == 1 ; jumps
            ;mov eax, bii.address
            Invoke DbgGetBranchDestination, dwCurrentAddress
            mov JmpDestination, eax
           ; PrintDec JmpDestination
            
            
            mov ebx, ptrJmpEntry
            mov eax, JmpDestination
            mov [ebx].JMPTABLE_ENTRY.dwAddress, eax
            
            inc nJmpEntry
            inc JMPTABLE_ENTRIES_TOTAL
            
            mov eax, JMPTABLE_ENTRIES_TOTAL
            .IF eax >= JMPTABLE_ENTRIES_MAX
                Invoke GuiAddStatusBarMessage, Addr szErrorMaxEntries
                mov eax, FALSE
                ret
            .ENDIF
            
            add ptrJmpEntry, SIZEOF JMPTABLE_ENTRY
        .ENDIF
        
        Invoke GuiGetDisassembly, dwCurrentAddress, Addr szDisasmText
        Invoke szLen, Addr szDisasmText
        add eax, 2 ; for CRLF pairs for each line
        add CLIPDATASIZE, eax

        mov eax, bii.size_ 
        add dwCurrentAddress, eax
        mov eax, dwCurrentAddress
    .ENDW    
    
    mov eax, JMPTABLE_ENTRIES_TOTAL
    mov ebx, 3 ; for extra label entries at start/finish for outside range labels
    mul ebx
    mov ebx, 96d ; LABEL_123456789 CRLF (18) + JMP LABEL_123456789 CRLF (22) = (40) round up = 64 + 16 for jmp outside range
    mul ebx
    add eax, 240d ;32d + 32d + 48d + 48d +8 +8 +20 +20; for additional comments
    add CLIPDATASIZE, eax
    
    
    ;PrintDec dwJmpTableSize
    ;PrintDec JMPTABLE_ENTRIES_MAX
    ;PrintDec JMPTABLE_ENTRIES_TOTAL
    ;DbgDump JMPTABLE, dwJmpTableSize
    
    mov eax, TRUE
    ret

CTABuildJmpTable ENDP


;-------------------------------------------------------------------------------------
; Frees memory of the jmptable and reset vars
;-------------------------------------------------------------------------------------
CTAClearJmpTable PROC
    
    mov JMPTABLE_ENTRIES_MAX, 0
    mov JMPTABLE_ENTRIES_TOTAL, 0
    mov eax, JMPTABLE
    .IF eax != 0
        Invoke GlobalFree, eax
    .ENDIF
    ret

CTAClearJmpTable ENDP


;-------------------------------------------------------------------------------------
; returns 0 if address is not in JMPTABLE, otherwise returns an 1-based index in eax
; each address can be checked to see if it a destination for a jmp instruction
; if it is then a label can be created an inserted before the instruction
; if it is a jmp instruction the jmp destination can be searched for and if found
; a jmp label can be inserted instead of the disassembled jmp instruction.
;-------------------------------------------------------------------------------------
CTAAddressInJmpTable PROC USES EBX dwAddress:DWORD
    LOCAL nJmpEntry:DWORD
    LOCAL ptrJmpEntry:DWORD
    
    .IF JMPTABLE == 0 || JMPTABLE_ENTRIES_TOTAL == 0
        mov eax, 0
        ret
    .ENDIF
    
    mov eax, JMPTABLE
    mov ptrJmpEntry, eax
    mov nJmpEntry, 0
    mov eax, 0
    .WHILE eax < JMPTABLE_ENTRIES_TOTAL
        mov ebx, ptrJmpEntry
        mov eax, [ebx].JMPTABLE_ENTRY.dwAddress
        .IF eax == dwAddress
            mov eax, nJmpEntry
            inc eax ; for 1 based index
            ret
        .ENDIF
        add ptrJmpEntry, SIZEOF JMPTABLE_ENTRY
        inc nJmpEntry
        mov eax, nJmpEntry
    .ENDW
    mov eax, 0
    ret
CTAAddressInJmpTable ENDP


;-------------------------------------------------------------------------------------
; Called before main loop output to clipboard labels outside range (before) selection
;-------------------------------------------------------------------------------------
CTAOutputLabelsOutsideRangeBefore PROC USES EBX dwStartAddress:DWORD, pDataBuffer:DWORD
    LOCAL nJmpEntry:DWORD
    LOCAL ptrJmpEntry:DWORD
    LOCAL bOutputComment:DWORD
    LOCAL dwAddress:DWORD
    
    .IF JMPTABLE == 0 || JMPTABLE_ENTRIES_TOTAL == 0
        mov eax, 0
        ret
    .ENDIF
    
    mov bOutputComment, FALSE
    
    mov eax, JMPTABLE
    mov ptrJmpEntry, eax
    mov nJmpEntry, 0
    mov eax, 0
    .WHILE eax < JMPTABLE_ENTRIES_TOTAL
        mov ebx, ptrJmpEntry
        mov eax, [ebx].JMPTABLE_ENTRY.dwAddress
        mov dwAddress, eax
        .IF eax < dwStartAddress
            .IF bOutputComment == FALSE
                Invoke szCatStr, pDataBuffer, Addr szCommentBeforeRange
                mov bOutputComment, TRUE 
            .ENDIF
            mov eax, nJmpEntry
            inc eax ; for 1 based index            
            Invoke CTALabelFromJmpEntry, eax, Addr szLabelX
            Invoke szCatStr, pDataBuffer, Addr szCRLF 
            Invoke szCatStr, pDataBuffer, Addr szLabelX
            Invoke dw2hex, dwAddress, Addr szValueString
            Invoke szCatStr, pDataBuffer, Addr szCmntStart
            Invoke szCatStr, pDataBuffer, Addr szValueString
            Invoke szCatStr, pDataBuffer, Addr szCRLF            

        .ENDIF
        add ptrJmpEntry, SIZEOF JMPTABLE_ENTRY
        inc nJmpEntry
        mov eax, nJmpEntry
    .ENDW
    mov eax, 0
    ret
CTAOutputLabelsOutsideRangeBefore ENDP


;-------------------------------------------------------------------------------------
; Called before main loop output to refview labels outside range (before) selection
;-------------------------------------------------------------------------------------
CTARefViewLabelsOutsideRangeBefore PROC USES EBX dwStartAddress:DWORD, dwCount:DWORD
    LOCAL nJmpEntry:DWORD
    LOCAL ptrJmpEntry:DWORD
    LOCAL dwAddress:DWORD
    LOCAL dwCTALIndex:DWORD
    
    .IF JMPTABLE == 0 || JMPTABLE_ENTRIES_TOTAL == 0
        mov eax, 0
        ret
    .ENDIF
    
    mov eax, dwCount
    mov dwCTALIndex, eax
    
    mov eax, JMPTABLE
    mov ptrJmpEntry, eax
    mov nJmpEntry, 0
    mov eax, 0
    .WHILE eax < JMPTABLE_ENTRIES_TOTAL
        mov ebx, ptrJmpEntry
        mov eax, [ebx].JMPTABLE_ENTRY.dwAddress
        mov dwAddress, eax
        .IF eax < dwStartAddress

            mov eax, nJmpEntry
            inc eax ; for 1 based index            
            Invoke CTALabelFromJmpEntry, eax, Addr szLabelX
            
            Invoke szCopy, Addr szLabelX, Addr szFormattedDisasmText
            Invoke dw2hex, dwAddress, Addr szValueString
            Invoke szCatStr, Addr szFormattedDisasmText, Addr szCmntStart
            Invoke szCatStr, Addr szFormattedDisasmText, Addr szValueString

            Invoke CTA_AddRowToRefView, dwCTALIndex, Addr szFormattedDisasmText
            inc dwCTALIndex

        .ENDIF
        add ptrJmpEntry, SIZEOF JMPTABLE_ENTRY
        inc nJmpEntry
        mov eax, nJmpEntry
    .ENDW
    mov eax, dwCTALIndex
    ret
CTARefViewLabelsOutsideRangeBefore ENDP


;-------------------------------------------------------------------------------------
; Called after main loop output to clipboard labels outside range (after) selection
;-------------------------------------------------------------------------------------
CTAOutputLabelsOutsideRangeAfter PROC USES EBX dwFinishAddress:DWORD, pDataBuffer:DWORD
    LOCAL nJmpEntry:DWORD
    LOCAL ptrJmpEntry:DWORD
    LOCAL bOutputComment:DWORD
    LOCAL dwAddress:DWORD
    
    .IF JMPTABLE == 0 || JMPTABLE_ENTRIES_TOTAL == 0
        mov eax, 0
        ret
    .ENDIF
    
    mov bOutputComment, FALSE
    
    mov eax, JMPTABLE
    mov ptrJmpEntry, eax
    mov nJmpEntry, 0
    mov eax, 0
    .WHILE eax < JMPTABLE_ENTRIES_TOTAL
        mov ebx, ptrJmpEntry
        mov eax, [ebx].JMPTABLE_ENTRY.dwAddress
        mov dwAddress, eax
        .IF eax > dwFinishAddress
            .IF bOutputComment == FALSE
                Invoke szCatStr, pDataBuffer, Addr szCommentAfterRange
                mov bOutputComment, TRUE 
            .ENDIF
            mov eax, nJmpEntry
            inc eax ; for 1 based index            
            Invoke CTALabelFromJmpEntry, eax, Addr szLabelX
            Invoke szCatStr, pDataBuffer, Addr szCRLF 
            Invoke szCatStr, pDataBuffer, Addr szLabelX
            Invoke dw2hex, dwAddress, Addr szValueString
            Invoke szCatStr, pDataBuffer, Addr szCmntStart
            Invoke szCatStr, pDataBuffer, Addr szValueString
            Invoke szCatStr, pDataBuffer, Addr szCRLF

        .ENDIF
        add ptrJmpEntry, SIZEOF JMPTABLE_ENTRY
        inc nJmpEntry
        mov eax, nJmpEntry
    .ENDW
    mov eax, 0
    ret
CTAOutputLabelsOutsideRangeAfter ENDP


;-------------------------------------------------------------------------------------
; Called before main loop output to refview labels outside range (after) selection
;-------------------------------------------------------------------------------------
CTARefViewLabelsOutsideRangeAfter PROC USES EBX dwFinishAddress:DWORD, dwCount:DWORD
    LOCAL nJmpEntry:DWORD
    LOCAL ptrJmpEntry:DWORD
    LOCAL dwAddress:DWORD
    LOCAL dwCTALIndex:DWORD
    
    .IF JMPTABLE == 0 || JMPTABLE_ENTRIES_TOTAL == 0
        mov eax, 0
        ret
    .ENDIF
    
    mov eax, dwCount
    mov dwCTALIndex, eax
    
    mov eax, JMPTABLE
    mov ptrJmpEntry, eax
    mov nJmpEntry, 0
    mov eax, 0
    .WHILE eax < JMPTABLE_ENTRIES_TOTAL
        mov ebx, ptrJmpEntry
        mov eax, [ebx].JMPTABLE_ENTRY.dwAddress
        mov dwAddress, eax
        .IF eax > dwFinishAddress

            mov eax, nJmpEntry
            inc eax ; for 1 based index            
            Invoke CTALabelFromJmpEntry, eax, Addr szLabelX
            
            Invoke szCopy, Addr szLabelX, Addr szFormattedDisasmText
            Invoke dw2hex, dwAddress, Addr szValueString
            Invoke szCatStr, Addr szFormattedDisasmText, Addr szCmntStart
            Invoke szCatStr, Addr szFormattedDisasmText, Addr szValueString

            Invoke CTA_AddRowToRefView, dwCTALIndex, Addr szFormattedDisasmText
            inc dwCTALIndex

        .ENDIF
        add ptrJmpEntry, SIZEOF JMPTABLE_ENTRY
        inc nJmpEntry
        mov eax, nJmpEntry
    .ENDW
    mov eax, dwCTALIndex
    ret
CTARefViewLabelsOutsideRangeAfter ENDP



;-------------------------------------------------------------------------------------
; Creates string "LABEL_X:"+(CRLF) from dwJmpEntry number X
;-------------------------------------------------------------------------------------
CTALabelFromJmpEntry PROC dwJmpEntry:DWORD, lpszLabel:DWORD
    LOCAL szValue[16]:BYTE
    .IF lpszLabel != NULL
        Invoke utoa_ex, dwJmpEntry, Addr szValue
        ;Invoke szCopy, Addr szCRLF, lpszLabel
        Invoke szCopy, Addr szLabel, lpszLabel
        ;Invoke szCatStr, lpszLabel, Addr szLabel
        Invoke szCatStr, lpszLabel, Addr szValue
        Invoke szCatStr, lpszLabel, Addr szColon
        ;Invoke szCatStr, lpszLabel, Addr szCRLF
    .ENDIF
    ret
CTALabelFromJmpEntry ENDP


;-------------------------------------------------------------------------------------
; Creates string for jump xxx instruction "jxxx LABEL_X" from dwJmpEntry number x
;-------------------------------------------------------------------------------------
CTAJmpLabelFromJmpEntry PROC USES EDI ESI dwJmpEntry:DWORD, bOutsideRange:DWORD, lpszJxxx:DWORD, lpszJumpLabel:DWORD
    LOCAL szValue[16]:BYTE
    LOCAL szJmp[16]:BYTE
    
    .IF lpszJxxx != NULL && lpszJumpLabel != NULL
        Invoke utoa_ex, dwJmpEntry, Addr szValue
        
        lea edi, szJmp
        mov esi, lpszJxxx
        
        movzx eax, byte ptr [esi]
        .WHILE al != 0
            .IF al == " " ; space
                mov byte ptr [edi], al
                inc edi
                .BREAK
            .ENDIF
            mov byte ptr [edi], al
            inc esi
            inc edi
            movzx eax, byte ptr [esi]
        .ENDW
        mov byte ptr [edi], 0h ; add null to string
        
        Invoke szCopy, Addr szJmp, lpszJumpLabel
        ;Invoke szCatStr, lpszJumpLabel, Addr szJmp
        Invoke szCatStr, lpszJumpLabel, Addr szLabel
        Invoke szCatStr, lpszJumpLabel, Addr szValue
        .IF bOutsideRange == TRUE
            Invoke szCatStr, lpszJumpLabel, Addr szCommentOutsideRange
        .ENDIF
        ;Invoke szCatStr, lpszLabel, Addr szCRLF
    .ENDIF
    ret
CTAJmpLabelFromJmpEntry ENDP


;-------------------------------------------------------------------------------------
; Adjust mnemonic to remove 0x and add h for masm style hex values
;-------------------------------------------------------------------------------------
CTAMnemonicToMasmHex PROC USES EBX EDI ESI lpszDisasmText:DWORD, lpszFormattedDisasmText:DWORD, bii:DWORD
    LOCAL szMnemToReplace[MAX_MNEMONIC_SIZE]:BYTE
    LOCAL szMnemToReplaceWith[MAX_MNEMONIC_SIZE]:BYTE
    LOCAL szTemp[MAX_MNEMONIC_SIZE]:BYTE
    LOCAL pMnemonic:DWORD
    
    mov ebx, bii
    lea eax, [ebx].BASIC_INSTRUCTION_INFO.memory.mnemonic
    mov pMnemonic, eax
    
    ; remove any *1- or *1+
    Invoke InString, 1, pMnemonic, Addr szMnemStarOnePlus
    .IF sdword ptr eax > 0
        Invoke szRep, pMnemonic, Addr szMnemToReplace, Addr szMnemStarOnePlus, Addr szPlus
    .ELSE
        Invoke InString, 1, pMnemonic, Addr szMnemStarOneMinus
        .IF sdword ptr eax > 0
            Invoke szRep, pMnemonic, Addr szMnemToReplace, Addr szMnemStarOneMinus, Addr szMinus
        .ELSE
            Invoke szCopy, pMnemonic, Addr szMnemToReplace
        .ENDIF
    .ENDIF
    
    ; remove any 0x in string
    Invoke InString, 1, Addr szMnemToReplace, Addr szHex
    .IF sdword ptr eax > 0
        Invoke szRep, szMnemToReplace, Addr szTemp, Addr szHex, Addr szNull
        Invoke szCopy, Addr szTemp, Addr szMnemToReplace
        
        Invoke InString, 1, Addr szMnemToReplace, Addr szHex
        .IF sdword ptr eax > 0
            Invoke szRep, szMnemToReplace, Addr szTemp, Addr szHex, Addr szNull
            Invoke szCopy, Addr szTemp, Addr szMnemToReplace
        .ENDIF
    .ENDIF
    
    Invoke szCopy, Addr szMnemToReplace, Addr szMnemToReplaceWith
    Invoke szCatStr, Addr szMnemToReplaceWith, Addr szMasmHexH    
    
    Invoke szRep, lpszDisasmText, lpszFormattedDisasmText, Addr szMnemToReplace, Addr szMnemToReplaceWith

    ret

CTAMnemonicToMasmHex ENDP



;=====================================================================================
; Strips out the brackets, underscores, full stops and @ symbols from calls: call <winbif._GetModuleHandleA@4> and returns just the api call: GetModuleHandle
; Returns true if succesful and lpszAPIFunction will contain the stripped api function name, otherwise false and lpszAPIFunction will be a null string
;-------------------------------------------------------------------------------------
Strip_x64dbg_calls PROC USES EDI ESI lpszCallText:DWORD, lpszAPIFunction:DWORD

    mov esi, lpszCallText
    mov edi, lpszAPIFunction
    
    movzx eax, byte ptr [esi]
    .WHILE al != '.' && al != '&' ; 64bit have & in the api calls, so to check for that as well
        .IF al == 0h
            mov edi, lpszAPIFunction
            mov byte ptr [edi], 0h ; null out string
            mov eax, FALSE
            ret
        .ENDIF
        inc esi
        movzx eax, byte ptr [esi]
    .ENDW

    inc esi ; jump over the . and the first _ if its there
    movzx eax, byte ptr [esi]
    .IF al == '_'
        inc esi
    .ENDIF

    movzx eax, byte ptr [esi]
    .WHILE al != '@' && al != '>'
        .IF al == 0h
            mov edi, lpszAPIFunction
            mov byte ptr [edi], 0h ; null out string
            mov eax, FALSE
            ret
        .ENDIF
        mov byte ptr [edi], al
        inc edi
        inc esi
        movzx eax, byte ptr [esi]
    .ENDW
    mov byte ptr [edi], 0h ; null out string
    
    mov eax, TRUE
    ret

Strip_x64dbg_calls endp


;=====================================================================================
; Strips out the segment text before brackets ss:[], ds:[] etc and any 0x
;-------------------------------------------------------------------------------------
Strip_x64dbg_segments PROC USES EBX EDI ESI lpszDisasmText:DWORD, lpszFormattedDisamText:DWORD

    mov esi, lpszDisasmText
    mov edi, lpszFormattedDisamText
    
    movzx eax, byte ptr [esi]
    .WHILE al != ':'
        .IF al == 0h
            mov byte ptr [edi], 0h ; add null to string
            mov eax, FALSE
            ret
;        .ELSEIF al == "x"
;            dec edi
;            dec edi
;        .ELSE
;            mov byte ptr [edi], al
        .ENDIF
        mov byte ptr [edi], al
        inc edi
        inc esi
        movzx eax, byte ptr [esi]
    .ENDW

    inc esi ; jump over the :, then skip back before segment text
    dec edi
    dec edi

    movzx eax, byte ptr [esi]
    .WHILE al != 0
        .IF al == "x"
            movzx ebx, byte ptr [esi-1]
            .IF bl == "0"
                dec edi
                dec edi
            .ELSE
                mov byte ptr [edi], al
            .ENDIF
        .ELSE
            mov byte ptr [edi], al
        .ENDIF
;        mov byte ptr [edi], al
        inc edi
        inc esi
        movzx eax, byte ptr [esi]
    .ENDW
    mov byte ptr [edi], 0h ; add null to string

    mov eax, TRUE

    ret

Strip_x64dbg_segments ENDP




;-------------------------------------------------------------------------------------
; Adds columns to the Reference View tab in x64dbg for displaying copied code
;-------------------------------------------------------------------------------------
CTA_AddColumnsToRefView PROC dwStartAddress:DWORD, dwFinishAddress:DWORD
    Invoke szCopy, addr szRefCopyToAsm, Addr szRefHdrMsg
    Invoke szCatStr, Addr szRefHdrMsg, Addr szModuleName
    Invoke szCatStr, Addr szRefHdrMsg, Addr szOffsetLeftBracket
    Invoke szCatStr, Addr szRefHdrMsg, Addr szHex
    Invoke dw2hex, dwStartAddress, Addr szValueString
    Invoke szCatStr, Addr szRefHdrMsg, Addr szValueString
    Invoke szCatStr, Addr szRefHdrMsg, Addr szModBaseHex
    Invoke szCatStr, Addr szRefHdrMsg, Addr szHex
    Invoke dw2hex, dwFinishAddress, Addr szValueString
    Invoke szCatStr, Addr szRefHdrMsg, Addr szValueString    
    Invoke szCatStr, Addr szRefHdrMsg, Addr szRightBracket
    Invoke GuiReferenceInitialize, Addr szRefHdrMsg
    Invoke GuiReferenceAddColumn, 0, Addr szRefAsmCode
    ;Invoke GuiReferenceSetCurrentTaskProgress, 0, Addr szRefCopyToAsmProcess
    Invoke GuiReferenceReloadData
    ret
CTA_AddColumnsToRefView ENDP


;-------------------------------------------------------------------------------------
; Adds a row of information about a code to the Reference View tab in x64dbg
;-------------------------------------------------------------------------------------
CTA_AddRowToRefView PROC dwCount:DWORD, lpszRowText:DWORD
    mov eax, dwCount
    inc eax
    Invoke GuiReferenceSetRowCount, eax
    Invoke GuiReferenceSetCellContent, dwCount, 0, lpszRowText
    mov eax, TRUE
    ret
CTA_AddRowToRefView ENDP



;--------------------------------------------------------------------------------------------------------------------
; Convert ascii string pointed to by String param to unsigned dword value. Returns dword value in eax.
;--------------------------------------------------------------------------------------------------------------------
OPTION PROLOGUE:NONE
OPTION EPILOGUE:NONE

align 16

atou_ex proc String:DWORD

  ; ------------------------------------------------
  ; Convert decimal string into UNSIGNED DWORD value
  ; ------------------------------------------------

    mov edx, [esp+4]

    xor ecx, ecx
    movzx eax, BYTE PTR [edx]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+1]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+2]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+3]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+4]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+5]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+6]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+7]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+8]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+9]
    test eax, eax
    jz quit

    lea ecx, [ecx+ecx*4]
    lea ecx, [eax+ecx*2-48]
    movzx eax, BYTE PTR [edx+10]
    test eax, eax
    jnz out_of_range

  quit:
    lea eax, [ecx]      ; return value in EAX
    or ecx, -1          ; non zero in ECX for success
    ret 4

  out_of_range:
    xor eax, eax        ; zero return value on error
    xor ecx, ecx        ; zero in ECX is out of range error
    ret 4

atou_ex endp

OPTION PROLOGUE:PrologueDef
OPTION EPILOGUE:EpilogueDef


; Paul Dixon's utoa_ex function. unsigned dword to ascii. 

OPTION PROLOGUE:NONE
OPTION EPILOGUE:NONE

    align 16

utoa_ex proc uvar:DWORD,pbuffer:DWORD

  ; --------------------------------------------------------------------------------
  ; this algorithm was written by Paul Dixon and has been converted to MASM notation
  ; --------------------------------------------------------------------------------

    mov eax, [esp+4]                ; uvar      : unsigned variable to convert
    mov ecx, [esp+8]                ; pbuffer   : pointer to result buffer

    push esi
    push edi

    jmp udword

  align 4
  chartab:
    dd "00","10","20","30","40","50","60","70","80","90"
    dd "01","11","21","31","41","51","61","71","81","91"
    dd "02","12","22","32","42","52","62","72","82","92"
    dd "03","13","23","33","43","53","63","73","83","93"
    dd "04","14","24","34","44","54","64","74","84","94"
    dd "05","15","25","35","45","55","65","75","85","95"
    dd "06","16","26","36","46","56","66","76","86","96"
    dd "07","17","27","37","47","57","67","77","87","97"
    dd "08","18","28","38","48","58","68","78","88","98"
    dd "09","19","29","39","49","59","69","79","89","99"

  udword:
    mov esi, ecx                    ; get pointer to answer
    mov edi, eax                    ; save a copy of the number

    mov edx, 0D1B71759h             ; =2^45\10000    13 bit extra shift
    mul edx                         ; gives 6 high digits in edx

    mov eax, 68DB9h                 ; =2^32\10000+1

    shr edx, 13                     ; correct for multiplier offset used to give better accuracy
    jz short skiphighdigits         ; if zero then don't need to process the top 6 digits

    mov ecx, edx                    ; get a copy of high digits
    imul ecx, 10000                 ; scale up high digits
    sub edi, ecx                    ; subtract high digits from original. EDI now = lower 4 digits

    mul edx                         ; get first 2 digits in edx
    mov ecx, 100                    ; load ready for later

    jnc short next1                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja   ZeroSupressed              ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    inc esi                         ; update pointer by 1
    jmp  ZS1                        ; continue with pairs of digits to the end

  align 16
  next1:
    mul ecx                         ; get next 2 digits
    jnc short next2                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja   ZS1a                       ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    add esi, 1                      ; update pointer by 1
    jmp  ZS2                        ; continue with pairs of digits to the end

  align 16
  next2:
    mul ecx                         ; get next 2 digits
    jnc short next3                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja   ZS2a                       ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    add esi, 1                      ; update pointer by 1
    jmp  ZS3                        ; continue with pairs of digits to the end

  align 16
  next3:

  skiphighdigits:
    mov eax, edi                    ; get lower 4 digits
    mov ecx, 100

    mov edx, 28F5C29h               ; 2^32\100 +1
    mul edx
    jnc short next4                 ; if zero, supress them by ignoring
    cmp edx, 9                      ; 1 digit or 2?
    ja  short ZS3a                  ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    inc esi                         ; update pointer by 1
    jmp short  ZS4                  ; continue with pairs of digits to the end

  align 16
  next4:
    mul ecx                         ; this is the last pair so don; t supress a single zero
    cmp edx, 9                      ; 1 digit or 2?
    ja  short ZS4a                  ; 2 digits, just continue with pairs of digits to the end

    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dh                   ; but only write the 1 we need, supress the leading zero
    mov byte ptr [esi+1], 0         ; zero terminate string

    pop edi
    pop esi
    ret 8

  align 16
  ZeroSupressed:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx
    add esi, 2                      ; write them to answer

  ZS1:
    mul ecx                         ; get next 2 digits
  ZS1a:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx                   ; write them to answer
    add esi, 2

  ZS2:
    mul ecx                         ; get next 2 digits
  ZS2a:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx                   ; write them to answer
    add esi, 2

  ZS3:
    mov eax, edi                    ; get lower 4 digits
    mov edx, 28F5C29h               ; 2^32\100 +1
    mul edx                         ; edx= top pair
  ZS3a:
    mov edx, chartab[edx*4]         ; look up 2 digits
    mov [esi], dx                   ; write to answer
    add esi, 2                      ; update pointer

  ZS4:
    mul ecx                         ; get final 2 digits
  ZS4a:
    mov edx, chartab[edx*4]         ; look them up
    mov [esi], dx                   ; write to answer

    mov byte ptr [esi+2], 0         ; zero terminate string

  sdwordend:

    pop edi
    pop esi

    ret 8

utoa_ex endp

OPTION PROLOGUE:PrologueDef
OPTION EPILOGUE:EpilogueDef




END DllMain















