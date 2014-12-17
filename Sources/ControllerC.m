#import "ControllerC.h"
#import <stdio.h>

BOOL checkWhich(NSString *cmdName)
{
	int status = system([NSString stringWithFormat:@"which %@ > /dev/null", cmdName].UTF8String);
	return (status == 0) ? YES : NO;
}

@implementation ControllerC
////// ここから OutputController プロトコルの実装 //////
- (void)clearOutputTextView
{	
}

- (void)showOutputDrawer
{
}

- (void)showMainWindow
{	
}

- (void)showNotFoundError:(NSString*)aPath
{
	fprintf(stderr, [NSString stringWithFormat:@"tex2img : %@ cannot be found.\nCheck environment variable $PATH.\n", aPath].UTF8String);
}

- (BOOL)platexExistsAtPath:(NSString*)platexPath dvipdfmxPath:(NSString*)dvipdfmxPath gsPath:(NSString*)gsPath
{
	if (!checkWhich(platexPath)) {
		[self showNotFoundError:@"platex"];
		return NO;
	}
	if (!checkWhich(dvipdfmxPath)) {
		[self showNotFoundError:@"dvipdfmx"];
		return NO;
	}
	if (!checkWhich(gsPath)) {
		[self showNotFoundError:@"gs"];
		return NO;
	}
	return YES;
}

- (BOOL)pdfcropExists;
{
	if (!checkWhich(@"pdfcrop")) {
		[self showNotFoundError:@"epstopdf"];
		return NO;
	}

	return YES;
}

- (BOOL)epstopdfExists;
{
	if (!checkWhich(@"pdfcrop")) {
		[self showNotFoundError:@"pdfcrop"];
		return NO;
	}
	
	return YES;
}

- (void)showExtensionError
{
	fprintf(stderr, "tex2img : The extention of output file must be either .eps/.png/.jpg/.pdf.\n");
}

- (void)showFileGenerateError:(NSString*)aPath
{
	fprintf(stderr, [NSString stringWithFormat:@"tex2img : %@ cannot be created so generation has been aborted.\nCheck permission.\n", aPath].UTF8String);
}

- (void)showExecError:(NSString*)command
{
	fprintf(stderr, [NSString stringWithFormat:@"tex2img : %@ cannot be executed.\nCheck errors in the source code.\n", command].UTF8String);
}

- (void)showCannotOverwriteError:(NSString*)path
{
	fprintf(stderr, [NSString stringWithFormat:@"tex2img : %@ cannot be overwritten.\n", path].UTF8String);
}

- (void)showCannotCreateDirectoryError:(NSString*)dir
{
    fprintf(stderr, [NSString stringWithFormat:@"tex2img : Directory %@ cannot be overwritten.\n", dir].UTF8String);
}

- (void)showCompileError
{
	fprintf(stderr, "tex2img : TeX Compile error.\nCheck errors in the source code.\n");
}

- (void)appendOutputAndScroll:(NSString*)str quiet:(BOOL)quiet
{
    if (!quiet) {
        printf(str.UTF8String);
    }
}
////// ここまで OutputController プロトコルの実装 //////


@end