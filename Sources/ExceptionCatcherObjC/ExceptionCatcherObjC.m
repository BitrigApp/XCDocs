#if !defined(__arm64__)
#error XCDocs requires arm64.
#endif

#import "ExceptionCatcherObjC.h"

NSError * _Nullable XCDocsCatchException(void (NS_NOESCAPE ^work)(void)) {
    @try {
        work();
        return nil;
    } @catch (NSException *exception) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        if (exception.reason != nil) {
            userInfo[NSLocalizedDescriptionKey] = exception.reason;
        } else {
            userInfo[NSLocalizedDescriptionKey] = @"Objective-C exception";
        }
        userInfo[@"XCDocsExceptionName"] = exception.name;
        if (exception.reason != nil) {
            userInfo[@"XCDocsExceptionReason"] = exception.reason;
        }
        return [NSError errorWithDomain:@"ExceptionCatcherObjC.Exception" code:1 userInfo:userInfo];
    }
}
