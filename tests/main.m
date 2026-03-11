#import "math_utils.h"

int main() {
    @autoreleasepool {
        int result = [MathUtils add:10 and:20];
        NSLog(@"Result: %d", result);
    }
    return 0;
}
