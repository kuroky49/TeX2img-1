#import <stdio.h>
#import <stdarg.h>
#import <getopt.h>
#import <Quartz/Quartz.h>
#import "Converter.h"
#import "ControllerC.h"
#import "global.h"
#import "UtilityC.h"
#import "NSString-Extension.h"
#import "NSDictionary-Extension.h"

#define OPTION_NUM 48
#define VERSION "2.0.3"
#define DEFAULT_MAXIMAL_NUMBER_OF_COMPILATION 3

#define ENABLED "enabled"
#define DISABLED "disabled"

void version()
{
    printf("tex2img Ver.%s\n", VERSION);
}

void usage()
{
	version();
    printf("Usage: tex2img [options] InputFile OutputFile\n");
    printf("Arguments:\n");
    printf("  InputFile  : path of a TeX source or PDF/PS/EPS file\n");
    printf("  OutputFile : path of an output file\n");
    printf("               (*extension: eps/pdf/svg/jpg/png/gif/tiff/bmp)\n");
    printf("Options:\n");
    printf("  --latex      COMPILER      : set the LaTeX compiler (default: platex)\n");
    printf("  *synonym: --compiler\n");
    printf("  --kanji      ENCODING      : set the Japanese encoding (no|utf8|sjis|jis|euc) (default: no)\n");
    printf("  --[no-]guess-compile       : disable/enable guessing the appropriate number of compilation (default: enabled)\n");
    printf("  --num        NUMBER        : set the (maximal) number of compilation\n");
    printf("  --dvidriver  DRIVER        : set the DVI driver    (default: dvipdfmx)\n");
    printf("  *synonym: --dviware, --dvipdfmx\n");
    printf("  --gs         GS            : set ghostscript (default: gs)\n");
    printf("  --resolution RESOLUTION    : set the resolution level (default: 15)\n");
    printf("  --left-margin    MARGIN    : set the left margin   (default: 0)\n");
    printf("  --right-margin   MARGIN    : set the right margin  (default: 0)\n");
    printf("  --top-margin     MARGIN    : set the top margin    (default: 0)\n");
    printf("  --bottom-margin  MARGIN    : set the bottom margin (default: 0)\n");
    printf("  --unit UNIT                : set the unit of margins to \"px\" or \"bp\" (default: px)\n");
    printf("                               (*bp is always used for EPS/PDF/SVG)\n");
    printf("  --[no-]transparent         : disable/enable transparent PNG/TIFF/GIF (default: enabled)\n");
    printf("  --[no-]with-text           : disable/enable text-embedded PDF (default: disabled)\n");
    printf("  --[no-]merge-output-files  : disable/enable merging products as a single file (PDF/TIFF) or animated GIF (default: disabled)\n");
    printf("  --animation-delay TIME     : set the delay time (sec) of an animated GIF (default: 1)\n");
    printf("  --animation-loop  NUMBER   : set the number of times to repeat an animated GIF (default: 0 (infinity))\n");
    printf("  --[no-]delete-display-size : disable/enable deleting width and height attributes of SVG (default: disabled)\n");
    printf("  --[no-]keep-page-size      : disable/enable keeping the original page size (default: disabled)\n");
    printf("  --pagebox BOX              : set the page box type used as the page size (media|crop|bleed|trim|art) (default: crop)\n");
    printf("  --[no-]ignore-errors       : disable/enable ignoring nonfatal errors (default: disabled)\n");
    printf("  --[no-]utf-export          : disable/enable substitution of \\UTF{xxxx} for non-JIS X 0208 characters (default: disabled)\n");
    printf("  --[no-]quick               : disable/enable speed priority mode (default: disabled)\n");
    printf("  --[no-]preview             : disable/enable opening products (default: disabled)\n");
    printf("  --[no-]delete-tmpfiles     : disable/enable deleting temporary files (default: enabled)\n");
    printf("  --[no-]embed-source        : disable/enable embedding of the source in products (default: enabled)\n");
    printf("  --[no-]copy-to-clipboard   : disable/enable copying products to the clipboard (default: disabled)\n");
    printf("  --[no-]quiet               : disable/enable quiet mode (default: disabled)\n");
    printf("  --version                  : display version info\n");
    printf("  --help                     : display this message\n");
    exit(1);
}

NSInteger strtoi(char *str)
{
	char *endptr;
	long val;
    
    errno = 0;    /* To distinguish success/failure after call */
    val = strtol(str, &endptr, 10);
	
    if ((errno == ERANGE && (val == LONG_MAX || val == LONG_MIN))
		|| (errno != 0 && val == 0)) {
		printStdErr("error : %s cannot be converted to a number.\n", str);
		exit(1);
    }
	
    if (*endptr != '\0') {
		printStdErr("error : %s is not a number.\n", str);
		exit(1);
	}
	
	return (NSInteger)val;
}

void printCurrentStatus(NSString *inputFilePath, NSDictionary<NSString*,id> *aProfile)
{
    printf("************************************\n");
    printf("  TeX2img settings\n");
    printf("************************************\n");
    printf("Input  file: %s\n", inputFilePath.UTF8String);

    NSString *outputFilePath = [aProfile stringForKey:OutputFileKey];
    printf("Output file: %s\n", outputFilePath.UTF8String);
    
    NSString *latex = [aProfile stringForKey:LatexPathKey];
    NSString *encoding = [aProfile stringForKey:EncodingKey];
    NSString *kanji;
    
    if ([encoding isEqualToString:PTEX_ENCODING_NONE]) {
        kanji = @"";
    } else {
        kanji = [@" -kanji=" stringByAppendingString:encoding];
    }
    
    printf("LaTeX compiler: %s%s %s\n", getPath(latex.programName).UTF8String, kanji.UTF8String, latex.argumentsString.UTF8String);

    printf("Auto detection of the number of compilation: ");
    if ([aProfile boolForKey:GuessCompilationKey]) {
        printf("enabled\n");
        printf("The maximal number of compilation: %ld\n", [aProfile integerForKey:NumberOfCompilationKey]);
    } else {
        printf("disabled\n");
        printf("The number of compilation: %ld\n", [aProfile integerForKey:NumberOfCompilationKey]);
    }

    NSString *dviware = [aProfile stringForKey:DviwarePathKey];
    printf("DVIware: %s %s\n", getPath(dviware.programName).UTF8String, dviware.argumentsString.UTF8String);

    NSString *gs = [aProfile stringForKey:GsPathKey];
    printf("Ghostscript: %s %s\n", getPath(gs.programName).UTF8String, gs.argumentsString.UTF8String);

    printf("epstopdf: %s\n", getPath([aProfile stringForKey:EpstopdfPathKey]).UTF8String);
    
    NSString *mudrawPath = getPath([aProfile stringForKey:MudrawPathKey]);
    printf("mudraw: %s\n", mudrawPath ? mudrawPath.UTF8String : "NOT FOUND");
    
    printf("Resolution level: %f\n", [aProfile floatForKey:ResolutionKey]);
    
    NSString *ext = outputFilePath.pathExtension;
    NSString *unit = (([aProfile integerForKey:UnitKey] == PX_UNIT_TAG) &&
                      ([ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"] || [ext isEqualToString:@"tiff"])) ?
                        @"px" : @"bp";

    printf("Left   margin: %ld%s\n", [aProfile integerForKey:LeftMarginKey], unit.UTF8String);
    printf("Right  margin: %ld%s\n", [aProfile integerForKey:RightMarginKey], unit.UTF8String);
    printf("Top    margin: %ld%s\n", [aProfile integerForKey:TopMarginKey], unit.UTF8String);
    printf("Bottom margin: %ld%s\n", [aProfile integerForKey:BottomMarginKey], unit.UTF8String);

    if ([ext isEqualToString:@"png"] || [ext isEqualToString:@"gif"] || [ext isEqualToString:@"tiff"]) {
        printf("Transparent PNG/GIF/TIFF: %s\n", [aProfile boolForKey:TransparentKey] ? ENABLED : DISABLED);
    }
    if ([ext isEqualToString:@"pdf"]) {
        printf("Text embedded PDF: %s\n", [aProfile boolForKey:GetOutlineKey] ? DISABLED : ENABLED);
    }
    if ([ext isEqualToString:@"svg"]) {
        printf("Delete width and height attributes of SVG: %s\n", [aProfile boolForKey:DeleteDisplaySizeKey] ? ENABLED : DISABLED);
    }
    printf("Ignore nonfatal errors: %s\n", [aProfile boolForKey:IgnoreErrorKey] ? ENABLED : DISABLED);
    printf("Substitute \\UTF{xxxx} for non-JIS X 0208 characters: %s\n", [aProfile boolForKey:UtfExportKey] ? ENABLED : DISABLED);
    printf("Conversion mode: %s priority mode\n", ([aProfile integerForKey:PriorityKey] == SPEED_PRIORITY_TAG) ? "speed" : "quality" );
    printf("Preview generated files: %s\n", [aProfile boolForKey:PreviewKey] ? ENABLED : DISABLED);
    printf("Delete temporary files: %s\n", [aProfile boolForKey:DeleteTmpFileKey] ? ENABLED : DISABLED);
    printf("Embed the source in generated files: %s\n", [aProfile boolForKey:EmbedSourceKey] ? ENABLED : DISABLED);
    printf("Copy generated files to the clipboard: %s\n", [aProfile boolForKey:CopyToClipboardKey] ? ENABLED : DISABLED);

    printf("************************************\n\n");
}

int main (int argc, char *argv[]) {
	@autoreleasepool {
        NSApplicationLoad(); // PDFKit を使ったときに _NXCreateWindow: error setting window property のエラーを防ぐため
        
        float resolutoinLevel = 15;
        NSInteger numberOfCompilation = -1;
        NSInteger leftMargin = 0;
        NSInteger rightMargin = 0;
        NSInteger topMargin = 0;
        NSInteger bottomMargin = 0;
        BOOL textPdfFlag = NO;
        BOOL transparentFlag = YES;
        BOOL deleteDisplaySizeFlag = NO;
        BOOL deleteTmpFileFlag = YES;
        BOOL ignoreErrorFlag = NO;
        BOOL utfExportFlag = NO;
        BOOL quietFlag = NO;
        BOOL quickFlag = NO;
        BOOL guessFlag = YES;
        BOOL previewFlag = NO;
        BOOL copyToClipboardFlag = NO;
        BOOL embedSourceFlag = YES;
        BOOL mergeFlag = NO;
        BOOL keepPageSizeFlag = NO;
        NSString *encoding = PTEX_ENCODING_NONE;
        NSString *latex    = @"platex";
        NSString *dviware  = @"dvipdfmx";
        NSString *gs       = @"gs";
        NSNumber *unitTag = @(PX_UNIT_TAG);
        CGPDFBox pageBoxType = kCGPDFCropBox;
        float delay = 1;
        NSInteger loopCount = 0;
        
        // getopt_long を使った，長いオプション対応のオプション解析
        struct option *options;
        int option_index;
        int opt;
        
        options = (struct option*)malloc(sizeof(struct option) * OPTION_NUM);
        
        NSUInteger i = 0;
        options[i].name = "resolution";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "left-margin";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "right-margin";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "top-margin";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "bottom-margin";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "with-text";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-with-text";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "transparent";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-transparent";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "delete-tmpfiles";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-delete-tmpfiles";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "ignore-errors";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-ignore-errors";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "utf-export";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-utf-export";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "kanji";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "quiet";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-quiet";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "unit";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "quick";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-quick";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "num";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "guess-compile";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-guess-compile";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "preview";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-preview";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "gs";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "embed-source";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-embed-source";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "delete-display-size";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-delete-display-size";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "copy-to-clipboard";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-copy-to-clipboard";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "latex";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "compiler";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "dvidriver";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "dviware";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "dvipdfmx";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "merge-output-files";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-merge-output-files";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "keep-page-size";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-keep-page-size";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "pagebox";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "animation-delay";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;
        
        i++;
        options[i].name = "animation-loop";
        options[i].has_arg = required_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        options[OPTION_NUM - 3].name = "version";
        options[OPTION_NUM - 3].has_arg = no_argument;
        options[OPTION_NUM - 3].flag = NULL;
        options[OPTION_NUM - 3].val = OPTION_NUM - 2;
        
        options[OPTION_NUM - 2].name = "help";
        options[OPTION_NUM - 2].has_arg = no_argument;
        options[OPTION_NUM - 2].flag = NULL;
        options[OPTION_NUM - 2].val = OPTION_NUM - 1;
        
        // 配列の最後は全てを0にしておく
        options[OPTION_NUM - 1].name = 0;
        options[OPTION_NUM - 1].has_arg = 0;
        options[OPTION_NUM - 1].flag = 0;
        options[OPTION_NUM - 1].val = 0;
        
        while (YES) {
            // オプションの取得
            opt = getopt_long(argc, argv, "", options, &option_index);
            
            // オプション文字が見つからなくなればオプション解析終了
            if (opt == -1) {
                break;
            }
            
            switch (opt) {
                case 0:
                    break;
                case 1: // --resolution
                    if (optarg) {
                        resolutoinLevel = strtof(optarg, NULL);
                    } else {
                        printf("--resolution is invalid.\n");
                        exit(1);
                    }
                    break;
                case 2: // --left-margin
                    if (optarg) {
                        leftMargin = strtoi(optarg);
                    } else {
                        printf("--left-margin is invalid.\n");
                        exit(1);
                    }
                    break;
                case 3: // --right-margin
                    if (optarg) {
                        rightMargin = strtoi(optarg);
                    } else {
                        printf("--right-margin is invalid.\n");
                        exit(1);
                    }
                    break;
                case 4: // --top-margin
                    if (optarg) {
                        topMargin = strtoi(optarg);
                    } else {
                        printf("--top-margin is invalid.\n");
                        exit(1);
                    }
                    break;
                case 5: // --bottom-margin
                    if (optarg) {
                        bottomMargin = strtoi(optarg);
                    } else {
                        printf("--bottom-margin is invalid.\n");
                        exit(1);
                    }
                    break;
                case 6: // --with-text
                    textPdfFlag = YES;
                    break;
                case 7: // --no-with-text
                    textPdfFlag = NO;
                    break;
                case 8: // --transparent
                    transparentFlag = YES;
                    break;
                case 9: // --no-transparent
                    transparentFlag = NO;
                    break;
                case 10: // --delete-tmpfiles
                    deleteTmpFileFlag = YES;
                    break;
                case 11: // --no-delete-tmpfiles
                    deleteTmpFileFlag = NO;
                    break;
                case 12: // --ignore-errors
                    ignoreErrorFlag = YES;
                    break;
                case 13: // --no-ignore-errors
                    ignoreErrorFlag = NO;
                    break;
                case 14: // --utf-export
                    utfExportFlag = YES;
                    break;
                case 15: // --no-utf-export
                    utfExportFlag = NO;
                    break;
                case 16: // --kanji
                    if (optarg) {
                        encoding = @(optarg);
                        if ([encoding isEqualToString:@"no"]) {
                            encoding = PTEX_ENCODING_NONE;
                        } else if (![encoding isEqualToString:PTEX_ENCODING_UTF8]
                                   && ![encoding isEqualToString:PTEX_ENCODING_SJIS]
                                   && ![encoding isEqualToString:PTEX_ENCODING_JIS]
                                   && ![encoding isEqualToString:PTEX_ENCODING_EUC]) {
                            printf("error: --kanji is invalid. It must be no/utf8/sjis/jis/euc.\n");
                            exit(1);
                        }
                    } else {
                        printf("error: --kanji is invalid. It must be no/utf8/sjis/jis/euc.\n");
                        exit(1);
                    }
                    break;
                case 17: // --quiet
                    quietFlag = YES;
                    break;
                case 18: // --no-quiet
                    quietFlag = NO;
                    break;
                case 19: // --unit
                    if (optarg) {
                        NSString *unitString = @(optarg);
                        if ([unitString isEqualToString:@"px"]) {
                            unitTag = @(PX_UNIT_TAG);
                        } else if ([unitString isEqualToString:@"bp"]) {
                            unitTag = @(BP_UNIT_TAG);
                        } else {
                            printf("error: --unit is invalid. It must be \"px\" or \"bp\".\n");
                            exit(1);
                        }
                    } else {
                        printf("error: --unit is invalid. It must be \"px\" or \"bp\".\n");
                        exit(1);
                    }
                    break;
                case 20: // --quick
                    quickFlag = YES;
                    break;
                case 21: // --no-quick
                    quickFlag = NO;
                    break;
                case 22: // --num
                    if (optarg) {
                        numberOfCompilation = strtoi(optarg);
                    } else {
                        printf("error: --num is invalid.\n");
                        exit(1);
                    }
                    break;
                case 23: // --guess-compile
                    guessFlag = YES;
                    break;
                case 24: // --no-guess-compile
                    guessFlag = NO;
                    break;
                case 25: // --preview
                    previewFlag = YES;
                    break;
                case 26: // --no-preview
                    previewFlag = NO;
                    break;
                case 27: // --gs
                    if (optarg) {
                        gs = @(optarg);
                    } else {
                        printf("error: --gs is invalid.\n");
                        exit(1);
                    }
                    break;
                case 28: // --embed-source
                    embedSourceFlag = YES;
                    break;
                case 29: // --no-embed-source
                    embedSourceFlag = NO;
                    break;
                case 30: // --delete-display-size
                    deleteDisplaySizeFlag = YES;
                    break;
                case 31: // --no-delete-display-size
                    deleteDisplaySizeFlag = NO;
                    break;
                case 32: // --copy-to-clipboard
                    copyToClipboardFlag = YES;
                    break;
                case 33: // --no-copy-to-clipboard
                    copyToClipboardFlag = NO;
                    break;
                case 34: // --latex
                    if (optarg) {
                        latex = @(optarg);
                    } else {
                        printf("error: --latex is invalid.\n");
                        exit(1);
                    }
                    break;
                case 35: // --compiler (synonym for --latex)
                    if (optarg) {
                        latex = @(optarg);
                    } else {
                        printf("error: --compiler is invalid.\n");
                        exit(1);
                    }
                    break;
                case 36: // --dvidriver
                    if (optarg) {
                        dviware = @(optarg);
                    } else {
                        printf("error: --dvidriver is invalid.\n");
                        exit(1);
                    }
                    break;
                case 37: // --dviware (synonym for --dvidriver)
                    if (optarg) {
                        dviware = @(optarg);
                    } else {
                        printf("error: --dviware is invalid.\n");
                        exit(1);
                    }
                    break;
                case 38: // --dvipdfmx (synonym for --dvidriver)
                    if (optarg) {
                        dviware = @(optarg);
                    } else {
                        printf("error: --dvipdfmx is invalid.\n");
                        exit(1);
                    }
                    break;
                case 39: // --merge-output-files
                    mergeFlag = YES;
                    break;
                case 40: // --no-merge-output-files
                    mergeFlag = NO;
                    break;
                case 41: // --keep-page-size
                    keepPageSizeFlag = YES;
                    break;
                case 42: // --no-keep-page-size
                    keepPageSizeFlag = NO;
                    break;
                case 43: // --pagebox
                    if (optarg) {
                        NSString *pageboxString = @(optarg);
                        if ([pageboxString isEqualToString:@"media"]) {
                            pageBoxType = kCGPDFMediaBox;
                        } else if ([pageboxString isEqualToString:@"crop"]) {
                            pageBoxType = kCGPDFCropBox;
                        } else if ([pageboxString isEqualToString:@"bleed"]) {
                            pageBoxType = kCGPDFBleedBox;
                        } else if ([pageboxString isEqualToString:@"trim"]) {
                            pageBoxType = kCGPDFTrimBox;
                        } else if ([pageboxString isEqualToString:@"art"]) {
                            pageBoxType = kCGPDFArtBox;
                        } else {
                            printf("error: --pagebox is invalid. It must be media/crop/bleed/trim/art.\n");
                            exit(1);
                        }
                    } else {
                        printf("error: --pagebox is invalid. It must be media/crop/bleed/trim/art.\n");
                        exit(1);
                    }
                    break;
                case 44: // --animation-delay
                    if (optarg) {
                        delay = strtof(optarg, NULL);
                    } else {
                        printf("--animation-delay is invalid.\n");
                        exit(1);
                    }
                    if (delay < 0) {
                        printf("--animation-delay is invalid.\n");
                        exit(1);
                    }
                    break;
                case 45: // --animation-loop
                    if (optarg) {
                        loopCount = strtoi(optarg);
                    } else {
                        printf("--animation-loop is invalid.\n");
                        exit(1);
                    }
                    if (loopCount < 0) {
                        printf("--animation-loop is invalid.\n");
                        exit(1);
                    }
                    break;
                case (OPTION_NUM - 2): // --version
                    version();
                    exit(1);
                    break;
                case (OPTION_NUM - 1): // --help
                    usage();
                    break;
                default:
                    usage();
                    break;
            }
        }
        
        argc -= optind; 
        argv += optind; 
        
        if (argc != 2) {
            usage();
        }
        
        NSString* inputFilePath = @(argv[0]);
        NSString* outputFilePath = getFullPath(@(argv[1]));
        
        if (!quietFlag) {
            version();
        }
        if (![NSFileManager.defaultManager fileExistsAtPath:inputFilePath]) {
            printStdErr("tex2img : No such file or directory - %s\n", inputFilePath.UTF8String);
            exit(1);
        }
        if (![InputExtensionsArray containsObject:inputFilePath.pathExtension]) {
            printStdErr("tex2img : Invalid input file type - %s\n", inputFilePath.UTF8String);
            exit(1);
        }
        
        // --num が指定されなかった場合のデフォルト値の適用
        if (numberOfCompilation == -1) {
            numberOfCompilation = guessFlag ? DEFAULT_MAXIMAL_NUMBER_OF_COMPILATION : 1;
        }
        
        ControllerC *controller = [ControllerC new];
        
        // 実行プログラムのパスチェック
        NSString *latexPath = getPath(latex.programPath);
        NSString *dviwarePath = getPath(dviware.programPath);
        NSString *gsPath = getPath(gs.programPath);
        NSString *epstopdfPath = getPath(@"epstopdf");
        NSString *mudrawPath = getPath(@"mudraw");
        
        if (!latexPath) {
            [controller showNotFoundError:latex.programName];
            suggestLatexOption();
            return 1;
        }
        if (!dviwarePath) {
            [controller showNotFoundError:dviware.programName];
            return 1;
        }
        if (!gsPath) {
            [controller showNotFoundError:gs.programName];
            return 1;
        }
        if (!epstopdfPath) {
            [controller showNotFoundError:@"epstopdf"];
            return 1;
        }
        if (!mudrawPath) {
            mudrawPath = @"mudraw";
        }
        
        NSMutableDictionary<NSString*,id> *aProfile = [NSMutableDictionary<NSString*,id> dictionary];
        
        aProfile[LatexPathKey] = [latexPath stringByAppendingStringSeparetedBySpace:latex.argumentsString];
        aProfile[DviwarePathKey] = [dviwarePath stringByAppendingStringSeparetedBySpace:dviware.argumentsString];
        aProfile[GsPathKey] = [gsPath stringByAppendingStringSeparetedBySpace:gs.argumentsString];
        aProfile[EpstopdfPathKey] = epstopdfPath;
        aProfile[MudrawPathKey] = mudrawPath;
        aProfile[OutputFileKey] = outputFilePath;
        aProfile[EncodingKey] = encoding;
        aProfile[NumberOfCompilationKey] = @(numberOfCompilation);
        aProfile[ResolutionKey] = @(resolutoinLevel);
        aProfile[LeftMarginKey] = @(leftMargin);
        aProfile[RightMarginKey] = @(rightMargin);
        aProfile[TopMarginKey] = @(topMargin);
        aProfile[BottomMarginKey] = @(bottomMargin);
        aProfile[GetOutlineKey] = @(!textPdfFlag);
        aProfile[TransparentKey] = @(transparentFlag);
        aProfile[DeleteDisplaySizeKey] = @(deleteDisplaySizeFlag);
        aProfile[ShowOutputDrawerKey] = @(NO);
        aProfile[PreviewKey] = @(previewFlag);
        aProfile[DeleteTmpFileKey] = @(deleteTmpFileFlag);
        aProfile[EmbedInIllustratorKey] = @(NO);
        aProfile[UngroupKey] = @(NO);
        aProfile[IgnoreErrorKey] = @(ignoreErrorFlag);
        aProfile[UtfExportKey] = @(utfExportFlag);
        aProfile[QuietKey] = @(quietFlag);
        aProfile[GuessCompilationKey] = @(guessFlag);
        aProfile[ControllerKey] = controller;
        aProfile[UnitKey] = unitTag;
        aProfile[PriorityKey] = quickFlag ? @(SPEED_PRIORITY_TAG) : @(QUALITY_PRIORITY_TAG);
        aProfile[CopyToClipboardKey] = @(copyToClipboardFlag);
        aProfile[EmbedSourceKey] = @(embedSourceFlag);
        aProfile[MergeOutputsKey] = @(mergeFlag);
        aProfile[KeepPageSizeKey] = @(keepPageSizeFlag);
        aProfile[PageBoxKey] = @(pageBoxType);
        aProfile[LoopCountKey] = @(loopCount);
        aProfile[DelayKey] = @(delay);
        
        if (!quietFlag) {
            printCurrentStatus(inputFilePath, aProfile);
        }
        
        Converter *converter = [Converter converterWithProfile:aProfile];
        BOOL success = [converter compileAndConvertWithInputPath:inputFilePath];
        
        return success ? 0 : 1;
    }
    
}
