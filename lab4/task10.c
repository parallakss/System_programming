#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define MAX_ATTEMPTS 5
#define PASSWORD "password123"

int main() {
    char input[32];
    int attempts = MAX_ATTEMPTS;
    
    while (attempts > 0) {
        printf("Enter password: ");
        if (fgets(input, sizeof(input), stdin) == NULL) {
            break;
        }
        
        // Убираем символ новой строки
        input[strcspn(input, "\n")] = 0;
        
        if (strcmp(input, PASSWORD) == 0) {
            printf("Success! Access granted.\n");
            return 0;
        } else {
            attempts--;
            if (attempts > 0) {
                printf("Wrong password. Try again.\n");
            }
        }
    }
    
    printf("Failure! Too many attempts.\n");
    return 1;
}