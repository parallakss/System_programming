#include <stdio.h>

int main() {
    int a, b, c;
    
    // Ввод данных
    printf("Enter a: ");
    scanf("%d", &a);
    
    printf("Enter b: ");
    scanf("%d", &b);
    
    printf("Enter c: ");
    scanf("%d", &c);
    
    // Вычисляем выражение: ((((a/b)-a)/b)*c)+a
    int result = ((((a / b) - a) / b) * c) + a;
    
    printf("Result: %d\n", result);
    return 0;
}