#include <stdio.h>
#include <stdlib.h>

int main() {
    int n;
    printf("Enter n: ");
    scanf("%d", &n);
    
    long long sum = 0;
    int sign = -1;  // для k=1: (-1)^1 = -1
    
    for (int k = 1; k <= n; k++) {
        long long term = (long long)k * (k + 1) * (3*k + 1) * (3*k + 2);
        sum += sign * term;
        sign = -sign;  // меняем знак для следующего члена
    }
    
    printf("Result: %lld\n", sum);
    return 0;
}