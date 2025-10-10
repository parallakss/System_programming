#include <stdio.h>

void reverse_digits(int m) {
    printf("Цифры числа %d в обратном порядке: ", m);
    
    if (m == 0) {
        printf("0");
    } else if (m < 0) {
        printf("-");
        m = -m;
    }
    
    while (m > 0) {
        printf("%d", m % 10);
        m /= 10;
    }
    printf("\n");
}

int main() {
    int m;
    printf("Введите число m: ");
    scanf("%d", &m);
    reverse_digits(m);
    return 0;
}