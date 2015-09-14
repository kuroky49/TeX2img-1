#import <Cocoa/Cocoa.h>

@protocol OutputController
- (void)showExtensionError;
- (void)showNotFoundError:(NSString*)aPath;
- (BOOL)latexExistsAtPath:(NSString*)latexPath dviwarePath:(NSString*)dviwarePath gsPath:(NSString*)gsPath;
- (BOOL)epstopdfExists;
- (BOOL)mudrawExists;
- (BOOL)tiffcpExists;
- (void)showFileFormatError:(NSString*)aPath;
- (void)showFileGenerationError:(NSString*)aPath;
- (void)showExecError:(NSString*)command;
- (void)showCannotOverwriteError:(NSString*)path;
- (void)showCannotCreateDirectoryError:(NSString*)dir;
- (void)showCompileError;
- (void)appendOutputAndScroll:(NSString*)str quiet:(BOOL)quiet;
- (void)prepareOutputTextView;
- (void)releaseOutputTextView;
- (void)showOutputDrawer;
- (void)showMainWindow;
- (void)showErrorsIgnoredWarning;
- (void)showPageSkippedWarning:(NSArray*)pages;
- (void)showWhitePageWarning:(NSArray*)pages;
- (BOOL)execCommand:(NSString*)command atDirectory:(NSString*)path withArguments:(NSArray*)arguments quiet:(BOOL)quiet;
- (void)previewFiles:(NSArray*)files withApplication:(NSString*)app;
- (void)printResult:(NSArray*)generatedFiles quiet:(BOOL)quiet;
- (void)generationDidFinish;
- (void)exitCurrentThreadIfTaskKilled;
@end

@interface Converter : NSObject
+ (Converter*)converterWithProfile:(NSDictionary*)aProfile;
- (BOOL)compileAndConvertWithInputPath:(NSString*)sourcePath;
- (BOOL)compileAndConvertWithSource:(NSString*)texSourceStr;
- (BOOL)compileAndConvertWithBody:(NSString*)texBodyStr;
- (NSUInteger)pageCount;
- (void)deleteTemporaryFiles;
@end
