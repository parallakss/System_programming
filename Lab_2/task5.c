#include <stdio.h>

int main() {
    unsigned long long number = 2634342072;
    unsigned long long sum = 0;
    unsigned long long n = number;
    
    while (n > 0) {
        sum += n % 10;
        n /= 10;
    }
    
    printf("%llu\n", sum);
    return 0;
}