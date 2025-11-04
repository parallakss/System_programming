#include <stdio.h>
#include <stdlib.h>

int main() {
    int n;
    printf("Enter n: ");
    scanf("%d", &n);
    
    int sum = 0;
    int sign = 1;
    
    for (int k = 1; k <= n; k++) {
        sum += sign * k * k;
        sign = -sign;  // меняем знак для следующего члена
    }
    
    printf("Result: %d\n", sum);
    return 0;
}