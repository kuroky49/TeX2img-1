NSString *commandCompletionChar;
NSMutableString *commandCompletionList;

#define MAX_LEN 2048
#define BASH_PATH @"/bin/bash"

#define TargetExtensionsArray (@[@"eps", @"png", @"jpg", @"gif", @"tiff", @"bmp", @"pdf", @"svg"])
#define ImportExtensionsArray (@[@"eps", @"png", @"jpg", @"gif", @"tiff", @"bmp", @"pdf", @"svg", @"tex"])
#define InputExtensionsArray (@[@"tex", @"pdf", @"ps", @"eps"])

#define ProfileNamesKey @"profileNames"
#define ProfilesKey @"profiles"

#define XKey @"x"
#define YKey @"y"
#define MainWindowWidthKey @"mainWindowWidth"
#define MainWindowHeightKey @"mainWindowHeight"
#define OutputFileKey @"outputFile"
#define ShowOutputDrawerKey @"showOutputDrawer"
#define ThreadingKey @"threading"
#define PreviewKey @"preview"
#define DeleteTmpFileKey @"deleteTmpFile"
#define CopyToClipboardKey @"copyToClipboard"
#define EmbedInIllustratorKey @"embedInIllustrator"
#define UngroupKey @"ungroup"
#define TransparentKey @"transparent"
#define GetOutlineKey @"getOutline"
#define DeleteDisplaySizeKey @"deleteDisplaySize"
#define MergeOutputsKey @"mergeOutputs"
#define KeepPageSizeKey @"keepPageSize"
#define IgnoreErrorKey @"ignoreError"
#define UtfExportKey @"utfExport"
#define LatexPathKey @"platexPath"
// DviwarePathKey の内容は，互換性を考えて "dvipdfmxPath" のままで維持
#define DviwarePathKey @"dvipdfmxPath"
#define GsPathKey @"gsPath"
#define GuessCompilationKey @"guessCompilation"
#define NumberOfCompilationKey @"numberOfCompilation"
#define ResolutionLabelKey @"resolutionLabel"
#define LeftMarginLabelKey @"leftMarginLabel"
#define RightMarginLabelKey @"rightMarginLabel"
#define TopMarginLabelKey @"topMarginLabel"
#define BottomMarginLabelKey @"bottomMarginLabel"
#define ResolutionKey @"resolution"
#define LeftMarginKey @"leftMargin"
#define RightMarginKey @"rightMargin"
#define TopMarginKey @"topMargin"
#define BottomMarginKey @"bottomMargin"
#define UnitKey @"unit"
#define PriorityKey @"priority"
#define EmbedSourceKey @"embedSource"
#define TabWidthKey @"tabWidth"
#define TabIndentKey @"tabIndent"
#define WrapLineKey @"warpLines"

#define ForegroundColorKey @"foregroundColor"
#define BackgroundColorKey @"backgroundColor"
#define CursorColorKey @"cursorColor"
#define BraceColorKey @"braceColor"
#define CommentColorKey @"commentColor"
#define CommandColorKey @"commandColor"
#define InvisibleColorKey @"invisibleColor"
#define HighlightedBraceColorKey @"highlightedBraceColor"
#define EnclosedContentBackgroundColorKey @"enclosedContentBackgroundColor"
#define FlashingBackgroundColorKey @"flashingBackgroundColor"
#define MakeatletterEnabledKey @"makeatletterEnabled"

#define ColorPalleteColorKey @"colorPalleteColor"

#define ConvertYenMarkKey @"convertYenMark"
#define FlashInMovingKey @"flashInMoving"
#define HighlightContentKey @"highlightContent"
#define BeepKey @"beep"
#define FlashBackgroundKey @"flashBackground"
#define CheckBraceKey @"checkBrace"
#define CheckBracketKey @"checkBracket"
#define CheckSquareBracketKey @"checkSquareBracket"
#define CheckParenKey @"checkParen"
#define AutoCompleteKey @"autoComplete"
#define ShowTabCharacterKey @"showTabCharacter"
#define ShowSpaceCharacterKey @"showSpaceCharacter"
#define ShowFullwidthSpaceCharacterKey @"showFullwidthSpaceCharacter"
#define ShowNewLineCharacterKey @"showNewLineCharacter"
#define SourceFontNameKey @"sourceFontName"
#define SourceFontSizeKey @"sourceFontSize"
#define PreambleKey @"preamble"
#define InputMethodKey @"inputMethod"
#define InputSourceFilePathKey @"inputSourceFilePath"
#define EncodingKey @"encoding"
#define EpstopdfPathKey @"epstopdfPath"
#define MudrawPathKey @"mudrawPath"
#define TiffcpPathKey @"tiffcpPath"
#define QuietKey @"quiet"

#define AutoDetectionTargetKey @"autoDetectionTarget"
#define SpaceCharacterKindKey @"spaceCharacterKind"
#define FullwidthSpaceCharacterKindKey @"fullwidthSpaceCharacterKind"
#define ReturnCharacterKindKey @"returnCharacterKind"
#define TabCharacterKindKey @"tabCharacterKind"
#define PageBoxKey @"pageBox"

#define ControllerKey @"controller"
#define TeX2imgVersionKey @"TeX2imgVersion"

#define PX_UNIT_TAG 1
#define BP_UNIT_TAG 2
#define QUALITY_PRIORITY_TAG 1
#define SPEED_PRIORITY_TAG 2
#define DIRECT_INPUT_TAG 0
#define INPUT_FILE_TAG 1

#define COLOR_TAG 1
#define TEXTCOLOR_TAG 2
#define COLORBOX_TAG 3
#define DEFINECOLOR_TAG 4

#define CommentOutTag 1
#define UncommentTag 2
#define ShiftRightTag 3
#define ShiftLeftTag 4

#define NFC_Tag 1
#define Modified_NFC_Tag 2
#define NFD_Tag 3
#define Modified_NFD_Tag 4
#define NFKC_Tag 5
#define NFKD_Tag 6
#define NFKC_CF_Tag 7

#define TeXtoDVItoPDF 1
#define TeXtoPDF 2

#define PTEX_ENCODING_NONE @"none"
#define PTEX_ENCODING_UTF8 @"utf8"
#define PTEX_ENCODING_SJIS @"sjis"
#define PTEX_ENCODING_JIS @"jis"
#define PTEX_ENCODING_EUC @"euc"

#define EA_Key "com.loveinequality.TeX2img"

#define ADDITIONAL_PATH @"/Applications/TeX2img.app/Contents/Resources/mupdf:/Applications/TeXLive/TeX2img.app/Contents/Resources/mupdf:/Applications/TeX2img.app/Contents/Resources/libtiff:/Applications/TeXLive/TeX2img.app/Contents/Resources/libtiff"
