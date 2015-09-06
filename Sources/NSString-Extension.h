#import <Foundation/Foundation.h>

@interface NSString (Extension)
+ (NSString*)UUIDString;
- (NSString*)pathStringByAppendingPageNumber:(NSUInteger)page;
- (NSString*)stringByDeletingLastReturnCharacters;
- (NSString*)programPath;
- (NSString*)programName;
- (NSString*)argumentsString;
- (NSString*)stringByAppendingStringSeparetedBySpace:(NSString*)string;
- (NSUInteger)numberOfComposedCharacters;
+ (NSString*)stringWithUTF32Char:(UTF32Char)character;
+ (NSString*)stringWithAutoEncodingDetectionOfData:(NSData*)data detectedEncoding:(NSStringEncoding*)encoding;
@end
