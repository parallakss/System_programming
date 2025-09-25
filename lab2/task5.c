#include <stdio.h>

int main() {
    long long N = 2634342072;
    long long sum = 0;
    long long temp = N;
    
    while (temp > 0) {
        sum += temp % 10;
        temp /= 10;
    }
    
    printf("Sum of digits: %lld\n", sum);
    return 0;
}