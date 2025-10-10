#include <stdio.h>
#include <string.h>

int main() {
    char password[20];
    char correct_password[] = "secret123";
    int attempts = 5;
    int authenticated = 0;
    
    while (attempts > 0 && !authenticated) {
        printf("Введите пароль (осталось попыток: %d): ", attempts);
        scanf("%19s", password);
        
        if (strcmp(password, correct_password) == 0) {
            authenticated = 1;
            printf("Вход\n");
        } else {
            printf("Неверный пароль\n");
            attempts--;
        }
    }
    
    if (!authenticated) {
        printf("Неудача\n");
    }
    
    return 0;
}