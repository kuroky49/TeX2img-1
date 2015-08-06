#import <stdio.h>
#import <stdarg.h>
#import <getopt.h>
#import "Converter.h"
#import "ControllerC.h"
#import "global.h"
#import "UtilityC.h"
#import "NSString-Extension.h"

#define OPTION_NUM 38
#define VERSION "1.9.7"
#define DEFAULT_MAXIMAL_NUMBER_OF_COMPILATION 3

static void version()
{
    printf("tex2img Ver.%s\n", VERSION);
}

static void usage()
{
	version();
    printf("Usage: tex2img [options] InputFile OutputFile\n");
    printf("Arguments:\n");
    printf("  InputFile                  : path of TeX source or PDF file\n");
    printf("  OutputFile                 : path of output file (extension: eps/pdf/svg/jpg/png/gif/tiff/bmp)\n");
    printf("Options:\n");
    printf("  --compiler   COMPILER      : set compiler      (default: platex)\n");
    printf("  --kanji ENCODING           : set Japanese encoding (no|utf8|sjis|jis|euc) (default: no)\n");
    printf("  --[no-]guess-compile       : guess the appropriate number of compilation (default: no)\n");
    printf("  --num        NUMBER        : set the (maximal) number of compilation\n");
    printf("  --dvipdfmx   DVIPDFMX      : set dvipdfmx      (default: dvipdfmx)\n");
    printf("  --gs         GS            : set ghostscript   (default: gs)\n");
    printf("  --resolution RESOLUTION    : set resolution level (default: 15)\n");
    printf("  --left-margin    MARGIN    : set the left margin   (default: 0)\n");
    printf("  --right-margin   MARGIN    : set the right margin  (default: 0)\n");
    printf("  --top-margin     MARGIN    : set the top margin    (default: 0)\n");
    printf("  --bottom-margin  MARGIN    : set the bottom margin (default: 0)\n");
    printf("  --unit UNIT                : set the unit of margins to \"px\" or \"bp\" (default: px)\n");
    printf("                               (*bp is always used for EPS/PDF/SVG)\n");
    printf("  --[no-]with-text           : generate text-embedded PDF files (default: no)\n");
    printf("  --[no-]transparent         : generate transparent images (for PNG/GIF/TIFF) (default: no)\n");
    printf("  --[no-]delete-display-size : delete width and height attributes of SVG files (default: no)\n");
    printf("  --[no-]copy-to-clipboard   : copy generated files to the clipboard (default: no)\n");
    printf("  --[no-]embed-source        : embed the source into image files (default: no)\n");
    printf("  --[no-]quick               : convert in a speed priority mode (default: no)\n");
    printf("  --[no-]ignore-errors       : force conversion by ignoring nonfatal errors (default: no)\n");
    printf("  --[no-]utf-export          : substitute \\UTF{xxxx} for non-JIS X 0208 characters (default: no)\n");
    printf("  --[no-]quiet               : do not output logs or messages (default: no)\n");
    printf("  --[no-]debug               : leave temporary files for debug (default: no)\n");
    printf("  --[no-]preview             : open the generated files (default: no)\n");
    printf("  --version                  : display version info\n");
    printf("  --help                     : display this message\n");
    exit(1);
}

NSString* getPath(NSString *cmdName)
{
	char str[MAX_LEN];
	FILE *fp;
	char *pStr;
    
	if ((fp = popen([NSString stringWithFormat:@"PATH=$PATH:%@; /usr/bin/which %@", ADDITIONAL_PATH, cmdName].UTF8String, "r")) == NULL) {
		return nil;
	}
	fgets(str, MAX_LEN-1, fp);
	
	pStr = str;
    while ((*pStr != '\r') && (*pStr != '\n') && (*pStr != EOF)) {
        pStr++;
    }
	*pStr = '\0';
	
    if (pclose(fp) == 0) {
        return @(str);
    } else {
        return nil;
    }
}

int strtoi(char *str)
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
	
	return (int)val;
}

int main (int argc, char *argv[]) {
	@autoreleasepool {
        NSApplicationLoad(); // PDFKit を使ったときに _NXCreateWindow: error setting window property のエラーを防ぐため
        
        float resolutoinLevel = 15;
        int numberOfCompilation = -1;
        int leftMargin = 0;
        int rightMargin = 0;
        int topMargin = 0;
        int bottomMargin = 0;
        BOOL textPdfFlag = NO;
        BOOL transparentFlag = NO;
        BOOL deleteDisplaySizeFlag = NO;
        BOOL deleteTmpFileFlag = YES;
        BOOL ignoreErrorFlag = NO;
        BOOL utfExportFlag = NO;
        BOOL quietFlag = NO;
        BOOL quickFlag = NO;
        BOOL guessFlag = NO;
        BOOL previewFlag = NO;
        BOOL copyToClipboardFlag = NO;
        BOOL embedSourceFlag = NO;
        NSString *encoding = PTEX_ENCODING_NONE;
        NSString *compiler = @"platex";
        NSString *dvipdfmx = @"dvipdfmx";
        NSString *gs       = @"gs";
        NSNumber *unitTag = @(PXUNITTAG);
        
        // getopt_long を使った，長いオプション対応のオプション解析
        struct option *options;
        int option_index;
        int opt;
        
        options = malloc(sizeof(struct option) * OPTION_NUM);
        
        int i = 0;
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
        options[i].name = "debug";
        options[i].has_arg = no_argument;
        options[i].flag = NULL;
        options[i].val = i+1;

        i++;
        options[i].name = "no-debug";
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
        options[i].name = "compiler";
        options[i].has_arg = required_argument;
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
        options[i].name = "dvipdfmx";
        options[i].has_arg = required_argument;
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
                        printf("--resolution is wrong.\n");
                        usage();
                    }
                    break;
                case 2: // --left-margin
                    if (optarg) {
                        leftMargin = strtoi(optarg);
                    } else {
                        printf("--left-margin is wrong.\n");
                        usage();
                    }
                    break;
                case 3: // --right-margin
                    if (optarg) {
                        rightMargin = strtoi(optarg);
                    } else {
                        printf("--right-margin is wrong.\n");
                        usage();
                    }
                    break;
                case 4: // --top-margin
                    if (optarg) {
                        topMargin = strtoi(optarg);
                    } else {
                        printf("--top-margin is wrong.\n");
                        usage();
                    }
                    break;
                case 5: // --bottom-margin
                    if (optarg) {
                        bottomMargin = strtoi(optarg);
                    } else {
                        printf("--bottom-margin is wrong.\n");
                        usage();
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
                case 10: // --debug
                    deleteTmpFileFlag = NO;
                    break;
                case 11: // --no-debug
                    deleteTmpFileFlag = YES;
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
                            printf("--kanji is wrong.\n");
                            usage();
                        }
                    } else {
                        printf("--kanji is wrong.\n");
                        usage();
                    }
                    break;
                case 17: // --quiet
                    quietFlag = YES;
                    break;
                case 18: // --no-quiet
                    quietFlag = NO;
                    break;
                case 19: // --compiler
                    if (optarg) {
                        compiler = @(optarg);
                    } else {
                        printf("--compiler is wrong.\n");
                        usage();
                    }
                    break;
                case 20: // --unit
                    if (optarg) {
                        NSString *unitString = @(optarg);
                        if ([unitString isEqualToString:@"px"]) {
                            unitTag = @(PXUNITTAG);
                        } else if ([unitString isEqualToString:@"bp"]) {
                            unitTag = @(BPUNITTAG);
                        } else {
                            printf("--unit is wrong.\n");
                            usage();
                        }
                    } else {
                        printf("--unit is wrong.\n");
                        usage();
                    }
                    break;
                case 21: // --quick
                    quickFlag = YES;
                    break;
                case 22: // --no-quick
                    quickFlag = NO;
                    break;
                case 23: // --num
                    if (optarg) {
                        numberOfCompilation = strtoi(optarg);
                    } else {
                        printf("--num is wrong.\n");
                        usage();
                    }
                    break;
                case 24: // --guess-compile
                    guessFlag = YES;
                    break;
                case 25: // --no-guess-compile
                    guessFlag = NO;
                    break;
                case 26: // --preview
                    previewFlag = YES;
                    break;
                case 27: // --no-preview
                    previewFlag = NO;
                    break;
                case 28: // --dvipdfmx
                    if (optarg) {
                        dvipdfmx = @(optarg);
                    } else {
                        printf("--dvipdfmx is wrong.\n");
                        usage();
                    }
                    break;
                case 29: // --gs
                    if (optarg) {
                        gs = @(optarg);
                    } else {
                        printf("--gs is wrong.\n");
                        usage();
                    }
                    break;
                case 30: // --embed-source
                    embedSourceFlag = YES;
                    break;
                case 31: // --no-embed-source
                    embedSourceFlag = NO;
                    break;
                case 32: // --delete-display-size
                    deleteDisplaySizeFlag = YES;
                    break;
                case 33: // --no-delete-display-size
                    deleteDisplaySizeFlag = NO;
                    break;
                case 34: // --copy-to-clipboard
                    copyToClipboardFlag = YES;
                    break;
                case 35: // --no-copy-to-clipboard
                    copyToClipboardFlag = NO;
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
            printStdErr("tex2img : %s : No such file or directory\n", inputFilePath.UTF8String);
            exit(1);
        }
        
        // --num が指定されなかった場合のデフォルト値の適用
        if (numberOfCompilation == -1) {
            numberOfCompilation = guessFlag ? DEFAULT_MAXIMAL_NUMBER_OF_COMPILATION : 1;
        }
        
        ControllerC *controller = ControllerC.new;
        
        // 実行プログラムのパスチェック
        NSString *latexPath = getPath(compiler.programPath);
        NSString *dvipdfmxPath = getPath(dvipdfmx.programPath);
        NSString *gsPath = getPath(gs.programPath);
        NSString *epstopdfPath = getPath(@"epstopdf");
        NSString *mudrawPath = getPath(@"mudraw");
        
        if (!latexPath) {
            [controller showNotFoundError:@"LaTeX"];
            return 1;
        }
        if (!dvipdfmxPath) {
            [controller showNotFoundError:@"dvipdfmx"];
            return 1;
        }
        if (!gsPath) {
            [controller showNotFoundError:@"gs"];
            return 1;
        }
        if (!epstopdfPath) {
            [controller showNotFoundError:@"epstopdf"];
            return 1;
        }
        if (!mudrawPath) {
            mudrawPath = @"mudraw";
        }
        
        NSMutableDictionary *aProfile = NSMutableDictionary.dictionary;
        aProfile[LatexPathKey] = [latexPath stringByAppendingStringSeparetedBySpace:compiler.argumentsString];
        aProfile[DvipdfmxPathKey] = [dvipdfmxPath stringByAppendingStringSeparetedBySpace:dvipdfmx.argumentsString];
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
        
        Converter *converter = [Converter converterWithProfile:aProfile];
        BOOL success = [converter compileAndConvertWithInputPath:inputFilePath];
        
        return success ? 0 : 1;
    }
    
}
