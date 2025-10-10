#include <stdio.h>

int main() {
    int n, count = 0;
    
    printf("Введите n: ");
    scanf("%d", &n);
    
    for (int i = 1; i <= n; i++) {
        if (i % 37 == 0 && i % 13 == 0) {
            count++;
        }
    }
    
    printf("Количество чисел от 1 до %d, делящихся на 37 и 13: %d\n", n, count);
    return 0;
}