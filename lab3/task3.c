#include <stdio.h>

int main() {
    int a, b, c;
    
    printf("Enter a: ");
    scanf("%d", &a);
    
    printf("Enter b: ");
    scanf("%d", &b);
    
    printf("Enter c: ");
    scanf("%d", &c);
    
    int result = ((((a / b) - a) / b) * c) + a;
    
    printf("Result: %d\n", result);
    return 0;
}