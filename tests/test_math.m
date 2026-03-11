#import <Foundation/Foundation.h>
#import "math_utils.h"
#import <stdio.h>
#import <stdlib.h>

int main() {
    @autoreleasepool {
        int result = [MathUtils add:1 and:2];
        if (result == 3) {
            printf("Test passed: 1 + 2 = 3\n");
            return 0;
        } else {
            printf("Test failed: 1 + 2 = %d\n", result);
            return 1;
        }
    }
}
