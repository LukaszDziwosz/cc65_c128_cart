/*
 * Simple C128 cartridge test program
 */

#include <stdio.h>
#include <conio.h>
#include <c128.h>

/* Function to display memory configuration */
void show_memory_config(void) {
    unsigned char mmu_val;
    
    /* Read MMU configuration register */
    mmu_val = *(unsigned char*)0xFF00;
    
    printf("MMU Configuration: $%02X\n", mmu_val);
    printf("RAM Banks: %d\n", (mmu_val >> 6) & 3);
    printf("$8000-$BFFF: ");
    
    switch ((mmu_val >> 2) & 3) {
        case 0: printf("BASIC ROM\n"); break;
        case 1: printf("Internal ROM\n"); break;
        case 2: printf("External ROM (Cartridge)\n"); break;
        case 3: printf("RAM\n"); break;
    }
}

/* Main program */
int main(void) {
    unsigned char key;
    
    /* Clear screen */
    clrscr();
    
    /* Display welcome message */
    textcolor(COLOR_LIGHTGREEN);
    cputs("C128 Cartridge Test Program\r\n");
    cputs("===========================\r\n\r\n");
    textcolor(COLOR_WHITE);
    
    /* Show where we're running from */
    printf("Code running from: $%04X\n", (unsigned int)main);
    printf("Stack pointer: $%04X\n\n", (unsigned int)&key);
    
    /* Display memory configuration */
    show_memory_config();
    
    /* Interactive menu */
    printf("\nOptions:\n");
    printf("1 - Test screen output\n");
    printf("2 - Test keyboard input\n");
    printf("3 - Show colors\n");
    printf("Q - Quit program\n\n");
    
    do {
        printf("Select option: ");
        key = cgetc();
        printf("%c\n", key);
        
        switch (key) {
            case '1':
                printf("Screen test: ");
                cputs("Hello from cartridge!\r\n");
                break;
                
            case '2':
                printf("Type a character: ");
                key = cgetc();
                printf("You typed: '%c' (code: %d)\n", key, key);
                key = '0'; /* Reset so we don't exit */
                break;
                
            case '3':
                {
                    unsigned char i;
                    printf("Available colors:\n");
                    for (i = 0; i < 16; ++i) {
                        textcolor(i);
                        cprintf("Color %2d ", i);
                        if ((i & 3) == 3) printf("\n");
                    }
                    textcolor(COLOR_WHITE);
                    printf("\n");
                }
                break;
        }
        
    } while (key != 'q' && key != 'Q');
    
    printf("\nGoodbye!\n");
    
    return 0;
}
