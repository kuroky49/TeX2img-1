#import <Foundation/Foundation.h>

@interface NSString (Extension)
+ (NSString*)UUIDString;
- (NSString*)pathStringByAppendingPageNumber:(NSUInteger)page;
- (NSString*)stringByDeletingLastReturnCharacters;
- (NSString*)stringByQuotingWithDoubleQuotations;
- (NSData*)dataUsingUTF8StringEncoding;
- (NSString*)programPath;
- (NSString*)programName;
- (NSString*)argumentsString;
- (NSString*)stringByAppendingStringSeparetedBySpace:(NSString*)string;
- (NSUInteger)numberOfComposedCharacters;
- (NSString*)pathStringWithHFSStyle;
+ (NSString*)stringWithUTF32Char:(UTF32Char)character;
+ (NSString*)stringWithAutoEncodingDetectionOfData:(NSData*)data detectedEncoding:(NSStringEncoding*)encoding;
@end
