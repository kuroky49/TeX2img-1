#import <stdio.h>
#import <stdarg.h>
#import "ControllerC.h"
#import "UtilityC.h"
#import "NSString-Extension.h"

@implementation ControllerC
#pragma mark OutputController プロトコルの実装
- (BOOL)execCommand:(NSString*)command atDirectory:(NSString*)path withArguments:(NSArray<NSString*>*)arguments quiet:(BOOL)quiet
{
    char str[MAX_LEN];
    FILE *fp;
    
    chdir(path.UTF8String);
    
    NSMutableString *cmdline = [NSMutableString string];
    [cmdline appendString:command];
    [cmdline appendString:@" "];
    
    for (NSString *argument in arguments) {
        [cmdline appendString:argument];
        [cmdline appendString:@" "];
    }

    [cmdline appendString:@"2>&1"];
    [self appendOutputAndScroll:[NSString stringWithFormat:@"$ %@\n", cmdline] quiet:quiet];
    
    if ((fp = popen(cmdline.UTF8String, "r")) == NULL) {
        return NO;
    }

    while (YES) {
        if (fgets(str, MAX_LEN-1, fp) == NULL) {
            break;
        }
        [self appendOutputAndScroll:[NSMutableString stringWithUTF8String:str] quiet:quiet];
    }

    NSInteger status = pclose(fp);
    return (status == 0) ? YES : NO;
}

- (void)prepareOutputTextView
{	
}

- (void)releaseOutputTextView
{
}

- (void)showOutputDrawer
{
}

- (void)showMainWindow
{	
}

- (BOOL)latexExistsAtPath:(NSString*)latexPath dviDriverPath:(NSString*)dviDriverPath gsPath:(NSString*)gsPath
{
	if (!checkWhich(latexPath)) {
		[self showNotFoundError:latexPath.programName];
        suggestLatexOption();
		return NO;
	}
	if (!checkWhich(dviDriverPath)) {
		[self showNotFoundError:dviDriverPath.programName];
		return NO;
	}
	if (!checkWhich(gsPath)) {
		[self showNotFoundError:gsPath.programName];
		return NO;
	}
	return YES;
}

- (BOOL)epstopdfExists;
{
	if (!checkWhich(@"epstopdf")) {
		[self showNotFoundError:@"epstopdf"];
		return NO;
	}
	
	return YES;
}

- (BOOL)mudrawExists;
{
    if (!checkWhich(@"mudraw")) {
        [self showNotFoundError:@"mudraw"];
        return NO;
    }
    
    return YES;
}

- (BOOL)pdftopsExists;
{
    if (!checkWhich(@"xpdf-pdftops") && !checkWhich(@"pdftops")) {
        [self showNotFoundError:@"pdftops"];
        return NO;
    }
    
    return YES;
}

- (BOOL)eps2emfExists;
{
    if (!checkWhich(@"eps2emf")) {
        printStdErr("tex2img: [Error] Place the GUI app (TeX2img.app) in /Applications.\n");
        return NO;
    }
    
    return YES;
}

- (void)showNotFoundError:(NSString*)aPath
{
    printStdErr("tex2img: [Error] Command \"%s\" cannot be found.\nCheck the environment variable $PATH.\n", aPath.UTF8String);
}

- (void)showExtensionError
{
    printStdErr("tex2img: [Error] The extention of output file must be either eps/pdf/jpg/png/gif/tiff/bmp/svg.\n");
}

- (void)showFileFormatError:(NSString*)aPath
{
    printStdErr("tex2img: [Error] Invalid file format: %s\n", aPath.UTF8String);
}

- (void)showFileGenerationError:(NSString*)aPath
{
	printStdErr("tex2img: [Error] %s cannot be created, and so generation has been aborted.\nCheck permission.\n", aPath.UTF8String);
}

- (void)showExecError:(NSString*)command
{
	printStdErr("tex2img: [Error] %s cannot be executed.\nCheck errors in the source code.\n", command.UTF8String);
}

- (void)showCannotOverwriteError:(NSString*)path
{
	printStdErr("tex2img: [Error] %s cannot be overwritten.\n", path.UTF8String);
}

- (void)showCannotCreateDirectoryError:(NSString*)dir
{
    printStdErr("tex2img: [Error] Directory %s cannot be overwritten.\n", dir.UTF8String);
}

- (void)showCompileError
{
	printStdErr("tex2img: [Error] A TeX compile error occurred.\nCheck errors in the source code.\n");
}

- (void)showImageSizeError
{
    printStdErr("tex2img: [Error] An image format error occurred.\nThe image size may be too large.\nTry lower the resolution level.\n");
}

- (void)appendOutputAndScroll:(NSString*)str quiet:(BOOL)quiet
{
    if (!quiet) {
        printf("%s", str.UTF8String);
    }
}

- (void)showErrorsIgnoredWarning
{
    printStdErr("tex2img: [Warning] Some errors were ignored. The result may be different from what you expected.\n");
}

- (void)showPageSkippedWarning:(NSArray<NSNumber*>*)pages
{
    if (pages.count > 1) {
        printStdErr("tex2img: [Warning] Page %s were empty and they were skipped.\n", [pages componentsJoinedByString:@", "].UTF8String);
    } else {
        printStdErr("tex2img: [Warning] Page %d was empty and it was skipped.\n", pages[0].integerValue);
    }
}

- (void)showWhitePageWarning:(NSArray<NSNumber*>*)pages
{
    if (pages.count > 1) {
        printStdErr("tex2img: [Warning] Page %s were empty and white pages were generated.\n", [pages componentsJoinedByString:@", "].UTF8String);
    } else {
        printStdErr("tex2img: [Warning] Page %d was empty and a white page was generated.\n", pages[0].integerValue);
    }
}

- (void)previewFiles:(NSArray<NSString*>*)files withApplication:(NSString*)app
{
    previewFiles(files, app);
}

- (void)printResult:(NSArray<NSString*>*)generatedFiles quiet:(BOOL)quiet
{
    NSUInteger count = generatedFiles.count;
    
    if (quiet) {
        return;
    }

    [self appendOutputAndScroll:@"\n" quiet:quiet];
    
    if (count > 1) {
        [self appendOutputAndScroll:[NSString stringWithFormat:@"TeX2img: %ld files were generated.\n", count]
                              quiet:quiet];
        [self appendOutputAndScroll:@"Generated files:\n" quiet:quiet];
    } else {
        [self appendOutputAndScroll:[NSString stringWithFormat:@"TeX2img: %ld file was generated.\n", count]
                              quiet:quiet];
        [self appendOutputAndScroll:@"Generated file:\n" quiet:quiet];
    }
    
    [generatedFiles enumerateObjectsUsingBlock:^(NSString *path, NSUInteger idx, BOOL *stop) {
        [self appendOutputAndScroll:[NSString stringWithFormat:@"%@\n", path]
                              quiet:quiet];
    }];
}

- (void)generationDidFinish
{
    
}

- (void)exitCurrentThreadIfTaskKilled
{
    
}
#pragma mark -


@end
