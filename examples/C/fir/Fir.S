    .global fir
fir:
    # Prologue: save callee-saved registers
    addi    sp, sp, -32
    sd      s0, 0(sp)
    sd      s1, 8(sp)
    sd      s2, 16(sp)

    # Compute constant: t2 = m - 1 (a4 holds m)
    addi    t2, a4, -1

    # Compute loop bound: bound = n - m + 1, using a3 (n) and a4 (m)
    sub     t3, a3, a4      # t3 = n - m
    addi    t3, t3, 1       # t3 = n - m + 1

    li      s0, 0           # j = 0 (outer loop counter)
forj:
    bge     s0, t3, donej   # if j >= (n - m + 1), exit outer loop

    li      s2, 0           # sum = 0

    # Compute base pointer for x:
    # t5 = a0 + ((j + m - 1) * 4)
    add     t5, s0, t2      # t5 = j + m - 1
    slli    t5, t5, 2       # multiply by 4 to get byte offset
    add     t5, a0, t5      # t5 now points to x[j + m - 1]

    # Set up pointer for c: copy a1 into t6
    addi    t6, a1, 0       # t6 = pointer to c[0]

    li      s1, 0           # i = 0 (inner loop counter)
fori:
    bge     s1, a4, donei   # if i >= m, exit inner loop

    lw      t1, 0(t5)       # load x[j + m - 1 - i]
    lw      t4, 0(t6)       # load c[i]
    mul     t4, t1, t4      # multiply: t4 = x * c
    srai    t4, t4, 31      # fixed-point scaling: (x * c << 1) >> 32
    add     s2, s2, t4      # accumulate into sum

    addi    t5, t5, -4      # decrement x pointer by one element (4 bytes)
    addi    t6, t6, 4       # increment c pointer by one element (4 bytes)
    addi    s1, s1, 1       # i++
    j       fori
donei:
    # Compute address for y[j] and store the sum
    slli    t0, s0, 2       # t0 = j * 4 (byte offset)
    add     t0, a2, t0      # t0 = &y[j]
    sw      s2, 0(t0)

    addi    s0, s0, 1       # j++
    j       forj

donej:
    # Epilogue: restore callee-saved registers and return
    ld      s0, 0(sp)
    ld      s1, 8(sp)
    ld      s2, 16(sp)
    addi    sp, sp, 32
    ret
