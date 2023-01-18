
mmc%=&fc80
mmcstat%=&fc81
acccon%=&fe34

.setIFJ
    PHA
    LDA        acccon%
    STA        &90
    ORA        #&20
    STA        acccon%
    PLA
    RTS

.restoreIFJ
    PHA
    LDA        &0090
    STA        acccon%
    PLA
    RTS

.MMC_GetByte
    JSR        setIFJ
    LDA        #0
    STA        mmcstat%
    LDA        #&ff
    STA        mmc%
.LAB_a5c7
    LDA        mmcstat%
    CMP        #0
    BNE        LAB_a5c7
    LDA        mmc%
    JSR        restoreIFJ
    RTS

.wait
    LDA        mmcstat%
    CMP        #0
    BNE        wait
    RTS
    JSR        setIFJ
.LAB_a5e0
    DEY
    BEQ        LAB_a5f4
    LDA        #&ff
    STA        mmc%
    JSR        wait
    LDA        mmc%
    STA        &00f8
    ROL        &00f8
    BCS        LAB_a5e0
.LAB_a5f4
    LDA        mmc%
    JSR        restoreIFJ
    RTS

.sendbyte
    PHA
    LDA        acccon%
    STA        &0090
    ORA        #&20
    STA        acccon%
    PLA
    STA        mmc%
.LAB_a60a
    LDA        mmcstat%
    CMP        #0
    BNE        LAB_a60a
    LDA        &0090
    STA        acccon%
    LDA        #0
    RTS

.sendbyte2

    STA        mmc%
.LAB_a61c
    LDA        mmcstat%
    CMP        #0
    BNE        LAB_a61c
    LDA        #0
    RTS

.MMC_DEVICE_RESET
    RTS

.MMC_16Clocks
    LDY        #2
.MMC_SlowClocks
.MMC_Clocks
    JSR        MMC_GetByte
    DEY
    BNE        MMC_Clocks
    RTS

.MMC_DoCommand
    JSR        setIFJ
    LDX        #0
    LDY        #8
.dcmd1
    LDA        cmdseq%,X
    STA        mmc%
    JSR        wait
    NOP
    NOP
    INX
    DEY
    BNE        dcmd1
    LDA        #&ff
.wR1mm
    STA        mmc%
    JSR        wait
    LDA        mmc%
    BPL        dcmdex
    DEY
    BNE        wR1mm
    CMP        #0
.dcmdex
    JSR        restoreIFJ
    RTS

.MMC_WaitForData
    JSR        setIFJ
    LDX        #&ff
.wl1
    STX        mmc%
    JSR        wait
    LDA        mmc%
    CMP        #&fe
    BNE        wl1
    JSR        restoreIFJ
    RTS

.MMC_Read256
    LDX        #0
    BEQ        LAB_a678

.MMC_ReadBLS
    LDX        &00c3
.LAB_a678
    LDY        #0
    LDA        TubeNoTransferIf0
    BNE        LAB_a6a2
    JSR        setIFJ
    LDA        #1
    STA        mmcstat%
.LAB_a687
    LDA        #&ff
    STA        mmc%
    JSR        wait
    NOP
    LDA        mmc%
    STA        (datptr%),Y
    INY
    DEX
    BNE        LAB_a687
    LDA        #0
    STA        mmcstat%
    JSR        restoreIFJ
    RTS
.LAB_a6a2
    TXA
    PHA
    JSR        MMC_GetByte
    STA        TUBE_R3_DATA
    PLA
    TAX
    INY
    DEX
    BNE        LAB_a6a2
    RTS

.MMC_ReadBuffer
    LDY        #&ff
    STY        CurrentCat
    INY
.rdl4
    JSR        MMC_GetByte
    STA        buf%,Y
    INY
    BNE        rdl4
    RTS

.MMC_SendingData
    LDY        #2
    JSR        MMC_Clocks
    LDA        #&fe
    JMP        sendbyte

.MMC_EndWrite
    JSR        MMC_16Clocks
.LAB_a6ce
    JSR        MMC_GetByte
    TAY
    AND        #&1f
    CMP        #&1f
    BEQ        LAB_a6ce
    CMP        #5
    BNE        errWrite2
.LAB_a6dc
    JSR        MMC_GetByte
    CMP        #&ff
    BNE        LAB_a6dc
    RTS

.MMC_Write256
    JSR        setIFJ
    LDA        #1
    STA        mmcstat%
    LDY        TubeNoTransferIf0
    BNE        LAB_a6fd
.LAB_a6f1
    LDA        (datptr%),Y
    JSR        sendbyte2
    INY
    BNE        LAB_a6f1
    JSR        restoreIFJ
    RTS
.LAB_a6fd
    LDY        #0
.LAB_a6ff
    LDA        TUBE_R3_DATA
    JSR        sendbyte2
    INY
    BNE        LAB_a6ff
    LDA        #0
    STA        mmcstat%
    JSR        restoreIFJ
    RTS

.MMC_WriteBuffer

    LDY        #0
.wbm1
    LDA        buf%,Y

    JSR        sendbyte
    INY
    BNE        wbm1
    RTS