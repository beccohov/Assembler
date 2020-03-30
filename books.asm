%include "io.inc"
section .bss
result_ resd 9
result__ resd 9
section .data
    first dd 0
    second dd 0
    third dd 0
    k dd 0,0,0,0,0,0,0,0,0;4100000000? 
    m dd 0,0,0,0,0,0,0,0,0 
    l dd 0,0,0,0,0,0,0,0,0   
    sign dd 1
section .text
global CMAIN
CMAIN:
    mov ebp, esp; for correct debugging
    GET_UDEC 4,first
    GET_UDEC 4,second
    GET_UDEC 4,third
    cmp dword[first],0
    jl negate_first
    first_after_negate:
    cmp dword[second],0
    jl negate_second
    second_after_negate:
    cmp dword[third],0
    jl negate_third
    third_after_negate:
    push dword[first]
    push k
    call FILL_NUMBER
    add esp, 8
    push dword[second]
    push m
    call FILL_NUMBER
    add esp, 8
    push k
    push m
    push result_
    call MULTIPLY_SEQUENCES
    call MAKE_SEQUENCE_CLEAR
    push dword[third]
    push l
    call FILL_NUMBER
    add esp,8
    push  l
    push result__
    call MULTIPLY_SEQUENCES
    call MAKE_SEQUENCE_CLEAR
    cmp dword[sign],0
    jl print_sign
    after_print_sign:    
    call PRINT_ULONG
    add esp,20
    xor eax,eax
    ret
  print_sign:
   PRINT_CHAR '-'
   jmp after_print_sign
  negate_first:
    neg dword[sign]
    neg dword[first]
    jmp first_after_negate
  negate_second:
    neg dword[sign]
    neg dword[second]
    jmp second_after_negate
  negate_third:
    neg dword[sign]
    neg dword[third]
    jmp third_after_negate
MAKE_SEQUENCE_CLEAR:  ; (superlong*)
    enter 0,0
    push ebx ;save
    push edi
    mov ebx, dword[ebp+8]
    mov ecx, 7
    mov edi, 10000
   lp_clear:
    cmp ecx,0
    jl end_cleaning
    mov eax,dword[ebx + 4*ecx + 4]
    xor edx ,edx
    div edi
    mov dword[ebx + 4*ecx + 4], edx
    add dword[ebx + 4*ecx], eax
    dec ecx
    jmp lp_clear
   end_cleaning:
    pop edi
    pop ebx
    leave
    ret
MULTIPLY_SEQUENCES: ;(superlong*res,superlong* first,superlong second)
    enter 0,0
    push ebx ;save for second_value indexing
    push edi ;save for result indexing
    push esi ;save for first_value indexing eax = i, ecx = j
    mov eax, 0 ;i = 0
    mov ecx, 0;j = 0   initial state
   external_loop:
    cmp eax,4
    jg final_multiply
    mov ecx,0 ;initial state
   internal_loop:
    cmp ecx,4
    jg final_internal_multiply
    mov edi,8
    sub edi, eax
    sub edi, ecx ; edi = (len*len-1) - (i+j),len = 3,becouse max number is less than max size 9 dwords
    mov ebx,8
    sub ebx, eax ; 8-i
    mov esi, 8
    sub esi, ecx ; 8 -j
    mov edx, dword[ebp+16]
    push eax ; save i
    mov eax, dword[edx + 4*ebx];eax = second[4-j]
    mov edx, dword[ebp +12]
    mul dword[edx + 4*esi]; eax = second[4-j]*first[4-i]
    mov edx,dword[ebp+8]
    add dword[edx + 4*edi],eax; reult[ (len*len-1) - (i+j)]+= second[4-j]*first[4-i]
    pop eax ;restore
    inc ecx
    jmp internal_loop
   final_internal_multiply:
    inc eax
    jmp external_loop
   final_multiply:
    pop esi
    pop edi
    pop ebx
    leave
    ret
    
FILL_NUMBER: ;(long*,number_32)
    enter 0,0
    push ebx ; save
    mov ecx, 8;bias
    mov eax, dword[ebp+12]
    mov ebx, dword[ebp+8];keep pointer
    push 10000 ; create locale variable
   record:
    cmp eax,0
    jz end_record
    xor edx,edx
    div dword[esp]
    mov dword[4*ecx+ebx],edx
    dec ecx ;next
    jmp record
   end_record:   
    add esp, 4 ; delete locale variable
    pop ebx
    leave 
    ret    
PRINT_ULONG: ;(long*) default length = 8 dwords
    push ebp
    mov ebp, esp
    push edi
    push ebx ; keep condition
    xor ebx,ebx
    xor eax,eax
    mov ecx,4;initial bias = 4,becouse first printed
    mov edi, dword[ebp+8]
    cmp dword[edi],0
    setz bl
    test bl,bl
    jnz next_print
    PRINT_UDEC 4, [edi]
    next_print:
    cmp ecx,32;max bias = 32 for 9 dword length
    jg printed   
    push ecx ; save  
    push ebx
    push dword[edi+ecx]
    call PRINT_SUPPORT
    mov ebx,eax;refresh flag
    add esp, 8
    pop ecx
    add ecx,4
    jmp next_print
   printed: 
    cmp ebx,0
    jz finally
    PRINT_CHAR '0'
    finally:
    pop ebx
    pop edi
    leave 
    ret
PRINT_SUPPORT: ;(address,flag)
    push ebp
    mov ebp,esp
    push ebx
    xor eax,eax
    mov ebx,dword[ebp+12];flag
    cmp dword[ebp+8],0
    setz al
    test bl,al
    jnz end_support ;if last prit is zero and current - too
    push dword[ebp+8]
    test bl,bl
    jnz print_without_padding
    call PRINT_DIGIT
    continue_support:
    add esp, 4
    mov eax,0 ;return next flag
    pop ebx
    leave
    ret
    end_support:
    mov eax,1 ;return next flag
    pop ebx
    leave
    ret
print_without_padding:
    PRINT_UDEC 4, [esp]
    jmp continue_support   
PRINT_DIGIT: ; (dword) unsigned   
    enter 0,0
    mov eax, dword[ebp+8]
    mov ecx,0
    cmp eax,0
    push 1
    cmovz ecx,dword[esp] ; for processing zero
    add esp,4
   find_out_count_print_digit: 
    cmp eax, 0
    jz continue_print_digit
    xor edx,edx
    push 10
    div dword[esp]
    add esp,4
    inc ecx
    jmp find_out_count_print_digit
   continue_print_digit:
     neg ecx
     add ecx,4
     lp_print_digit:
      cmp ecx,0
      jle cnt_print_digit
      dec ecx
      PRINT_CHAR '0'
      jmp lp_print_digit     
    cnt_print_digit:
     PRINT_UDEC 4, [ebp+8] 
    leave
    ret