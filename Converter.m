#import <stdio.h>
#import <unistd.h>
#import <Quartz/Quartz.h>
//#import <OgreKit/OgreKit.h>
#define MAX_LEN 1024

#import "Converter.h"

@implementation Converter
- (Converter*)initWithPlatex:(NSString*)_platexPath dvipdfmx:(NSString*)_dvipdfmxPath gs:(NSString*)_gsPath
			 withPdfcropPath:(NSString*)_pdfcropPath withEpstopdfPath:(NSString*)_epstopdfPath
					encoding:(NSString*)_encoding
			 resolutionLevel:(int)_resolutionLevel leftMargin:(int)_leftMargin rightMargin:(int)_rightMargin topMargin:(int)_topMargin bottomMargin:(int)_bottomMargin 
				   leaveText:(bool)_leaveTextFlag transparentPng:(bool)_transparentPngFlag 
			showOutputWindow:(bool)_showOutputWindowFlag preview:(bool)_previewFlag deleteTmpFile:(bool)_deleteTmpFileFlag
				ignoreErrors:(bool)_ignoreErrors
				  controller:(id<OutputController>)_controller
{
	platexPath = _platexPath;
	dvipdfmxPath = _dvipdfmxPath;
	gsPath = _gsPath;
	pdfcropPath = _pdfcropPath;
	epstopdfPath = _epstopdfPath;

	encoding = _encoding;
	resolutionLevel = _resolutionLevel;
	leftMargin = _leftMargin;
	rightMargin = _rightMargin;
	topMargin = _topMargin;
	bottomMargin = _bottomMargin;
	leaveTextFlag = _leaveTextFlag;
	transparentPngFlag = _transparentPngFlag;
	showOutputWindowFlag = _showOutputWindowFlag;
	previewFlag = _previewFlag;
	deleteTmpFileFlag = _deleteTmpFileFlag;
	ignoreErrorsFlag = _ignoreErrors;
	controller = _controller;
	
	fileManager = [NSFileManager defaultManager];
	tempdir = NSTemporaryDirectory();
	pid = (int)getpid();
	tempFileBaseName = [NSString stringWithFormat:@"temp%d", pid]; 

	return self;
}

+ (Converter*)converterWithPlatex:(NSString*)_platexPath dvipdfmx:(NSString*)_dvipdfmxPath gs:(NSString*)_gsPath
				  withPdfcropPath:(NSString*)_pdfcropPath withEpstopdfPath:(NSString*)_epstopdfPath
						 encoding:(NSString*)_encoding
				  resolutionLevel:(int)_resolutionLevel leftMargin:(int)_leftMargin rightMargin:(int)_rightMargin topMargin:(int)_topMargin bottomMargin:(int)_bottomMargin 
						leaveText:(bool)_leaveTextFlag transparentPng:(bool)_transparentPngFlag 
				 showOutputWindow:(bool)_showOutputWindowFlag preview:(bool)_previewFlag deleteTmpFile:(bool)_deleteTmpFileFlag
					 ignoreErrors:(bool)_ignoreErrors
					   controller:(id<OutputController>)_controller
{
	Converter* converter = [Converter alloc];
	[converter initWithPlatex:_platexPath dvipdfmx:_dvipdfmxPath gs:_gsPath
			  withPdfcropPath:_pdfcropPath withEpstopdfPath:_epstopdfPath
					 encoding:_encoding
			  resolutionLevel:_resolutionLevel leftMargin:_leftMargin rightMargin:_rightMargin topMargin:_topMargin bottomMargin:_bottomMargin 
					leaveText:_leaveTextFlag transparentPng:_transparentPngFlag 
			 showOutputWindow:_showOutputWindowFlag preview:_previewFlag deleteTmpFile:_deleteTmpFileFlag
				 ignoreErrors:_ignoreErrors
				   controller:_controller];
	return [converter autorelease];
}

// 文字列の円マーク・バックスラッシュを全てバックスラッシュに統一してファイルに書き込む。
// 返り値：書き込みの正否(bool)
- (bool)writeStringWithYenBackslashConverting:(NSString*)targetString toFile:(NSString*)path
{
	NSMutableString* mstr = [[[NSMutableString alloc] initWithCapacity:0] autorelease];
	[mstr appendString:targetString];

	NSString* yenMark = [NSString stringWithUTF8String:"\xC2\xA5"];
	NSString* backslash = [NSString stringWithUTF8String:"\x5C"];
	
	// 円マーク (0xC20xA5) をバックスラッシュ（0x5C）に置換
	[mstr replaceOccurrencesOfString:yenMark withString:backslash options:0 range:NSMakeRange(0, [mstr length])];	
	return [mstr writeToFile:path atomically:NO encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese) error:NULL];
	
	// バックスラッシュ（0x5C）を円マーク (0xC20xA5) に置換
	//NSString* yenMark = NSLocalizedString(@"YenMark", @"");
	//NSString* backslash = NSLocalizedString(@"Backslash", @"");
	//[mstr replaceOccurrencesOfString:backslash withString:yenMark options:0 range:NSMakeRange(0, [mstr length])];
	
	//// CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS) で保存すると，円マークは0x5cに，バックスラッシュは全角になって保存される。
	//return [mstr writeToFile:path atomically:NO encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingShiftJIS) error:NULL];

}


/*
 - (int)execCommand:(NSString*)command atDirectory:(NSString*)path withArguments:(NSArray*)arguments withStdout:(NSMutableString*)stdoutMStr withStdErr:(NSMutableString*)stderrMStr
 {
 NSTask* task = [[[NSTask alloc] init] autorelease];
 [task setCurrentDirectoryPath:path];
 [task setLaunchPath:command];
 [task setArguments:arguments];
 
 NSPipe* pipeStdout = [NSPipe pipe];
 NSPipe* pipeStdErr = [NSPipe pipe];
 [task setStandardOutput:pipeStdout];
 [task setStandardError:pipeStdErr];
 
 [task launch];
 [task waitUntilExit];
 
 char* stdoutChars = [[[pipeStdout fileHandleForReading] availableData] bytes];
 char* stderrChars = [[[pipeStdErr fileHandleForReading] availableData] bytes];
 
 if(stdoutMStr != nil && stdoutChars != nil)
 {
 [stdoutMStr appendString:[NSString stringWithCString:stdoutChars]];
 }
 if(stderrMStr != nil && stderrChars != nil)
 {
 [stderrMStr appendString:[NSString stringWithCString:stderrChars]];
 }
 
 return [task terminationStatus];
 }
*/

- (BOOL)execCommand:(NSString*)command atDirectory:(NSString*)path withArguments:(NSArray*)arguments withStdout:(NSMutableString*)stdoutMStr
{
	char str[MAX_LEN];
	FILE *fp;
	
	chdir([path cString]);
	
	NSMutableString *cmdline = [NSMutableString stringWithCapacity:0];
	[cmdline appendString:command];
	[cmdline appendString:@" "];
	
	NSEnumerator *enumerator = [arguments objectEnumerator];
	NSString *argument;
	while(argument = [enumerator nextObject])
	{
		[cmdline appendString:argument];
		[cmdline appendString:@" "];
	}
	[cmdline appendString:@" 2>&1"];
	[controller appendOutputAndScroll:[NSString stringWithFormat:@"$ %@\n", cmdline]];

	if((fp=popen([cmdline cString],"r"))==NULL)
	{
		return NO;
	}
	while(YES)
	{
		fgets(str, MAX_LEN-1, fp);
		if(feof(fp))
		{
			break;
		}
		[stdoutMStr appendString:[NSString stringWithCString:str]];
	}
	int status = pclose(fp);
	return (ignoreErrorsFlag || status==0) ? YES : NO;
	
}

- (int)tex2dvi:(NSString*)teXFilePath
{
	NSMutableString* outputMStr = [NSMutableString stringWithCapacity:0];
	int status = [self execCommand:platexPath atDirectory:tempdir withArguments:[NSArray arrayWithObjects:@"-interaction=nonstopmode", [NSString stringWithFormat:@"-kanji=%@", encoding], teXFilePath, nil] withStdout:outputMStr];
	if(outputMStr != nil)
	{
		[controller appendOutputAndScroll:outputMStr];
	}
	[controller appendOutputAndScroll:@"\n"];
	
	return status;
}

- (int)dvi2pdf:(NSString*)dviFilePath
{
	NSMutableString* outputMStr = [NSMutableString stringWithCapacity:0];
	int status = [self execCommand:dvipdfmxPath atDirectory:tempdir withArguments:[NSArray arrayWithObjects:@"-vv", dviFilePath, nil] withStdout:outputMStr];
	if(outputMStr != nil)
	{
		[controller appendOutputAndScroll:outputMStr];
	}
	[controller appendOutputAndScroll:@"\n"];	
	
	return status;
}

- (int)pdfcrop:(NSString*)pdfPath outputFileName:(NSString*)outputFileName addMargin:(bool)addMargin
{
	if(![controller checkPdfcropExistence])
	{
		return NO;
	}
	
	NSMutableString* outputMStr = [NSMutableString stringWithCapacity:0];
	int status = [self execCommand:[NSString stringWithFormat:@"export PATH=$PATH:%@;%@", [gsPath stringByDeletingLastPathComponent], pdfcropPath] atDirectory:tempdir
					 withArguments:[NSArray arrayWithObjects:
									addMargin ? [NSString stringWithFormat:@"--margins \"%d %d %d %d\"", leftMargin, topMargin, rightMargin, bottomMargin] : @"",
									[pdfPath lastPathComponent],
									outputFileName,
									nil] withStdout:outputMStr];
	[controller appendOutputAndScroll:outputMStr];
	
	return (status==0) ? YES : NO;
}

- (int)pdf2eps:(NSString*)pdfName outputEpsFileName:(NSString*)outputEpsFileName resolution:(int)resolution;
{
	NSMutableString* outputMStr = [NSMutableString stringWithCapacity:0];
	int status = [self execCommand:gsPath atDirectory:tempdir 
					 withArguments:[NSArray arrayWithObjects:
									@"-q",
									@"-sDEVICE=epswrite",
									@"-dNOPAUSE",
									@"-dBATCH",
									[NSString stringWithFormat:@"-r%d", resolution],
									[NSString stringWithFormat:@"-sOutputFile=%@", outputEpsFileName],
									[NSString stringWithFormat:@"%@.pdf", tempFileBaseName],
									nil]
						withStdout:outputMStr];
	[controller appendOutputAndScroll:outputMStr];
	return status;
}

- (bool)epstopdf:(NSString*)epsName outputPdfFileName:(NSString*)outputPdfFileName
{
	if(![controller checkEpstopdfExistence])
	{
		return NO;
	}
	
	[self execCommand:[NSString stringWithFormat:@"export PATH=%@;/usr/bin/perl %@", [gsPath stringByDeletingLastPathComponent], epstopdfPath] atDirectory:tempdir 
					 withArguments:[NSArray arrayWithObjects:
									[NSString stringWithFormat:@"--outfile=%@", outputPdfFileName],
									epsName,
									nil] withStdout:nil];
	return YES;
}

- (bool)eps2pdf:(NSString*)epsName outputFileName:(NSString*)outputFileName
{
	// まず，epstopdf を使って PDF に戻し，次に，pdfcrop を使って余白を付け加える
	NSString* trimFileName = [NSString stringWithFormat:@"%@.trim.pdf", epsName];
	if([self epstopdf:epsName outputPdfFileName:trimFileName] && [self pdfcrop:trimFileName outputFileName:outputFileName addMargin:YES])
	{
		return YES;
	}
	return NO;
}

// NSBitmapImageRep の背景を白く塗りつぶす
- (NSBitmapImageRep*)fillBackground:(NSBitmapImageRep*)bitmapRep
{
	NSImage *srcImage = [[[NSImage alloc] init] autorelease];
	[srcImage addRepresentation:bitmapRep];
	NSSize size = [srcImage size];
	
	NSImage *backgroundImage = [[[NSImage alloc] initWithSize:size] autorelease];
	[backgroundImage lockFocus];
	[[NSColor whiteColor] set];
	[NSBezierPath fillRect:NSMakeRect(0, 0, size.width, size.height)];
	[srcImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
	[backgroundImage unlockFocus];
	return [[[NSBitmapImageRep alloc] initWithData:[backgroundImage TIFFRepresentation]] autorelease];
}

- (void)pdf2image:(NSString*)pdfFilePath outputFileName:(NSString*)outputFileName
{
	NSString* extension = [[outputFileName pathExtension] lowercaseString];

	// PDFのバウンディングボックスで切り取る
	[self pdfcrop:pdfFilePath outputFileName:pdfFilePath addMargin:NO];
	
	// PDFの先頭ページを読み取り，NSPDFImageRep オブジェクトを作成
	NSData* pageData = [[[[[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:pdfFilePath]] autorelease] pageAtIndex:0] dataRepresentation];
	NSPDFImageRep *pdfImageRep = [[[NSPDFImageRep alloc] initWithData:pageData] autorelease];

	// 新しい NSImage オブジェクトを作成し，その中に NSPDFImageRep オブジェクトの中身を描画
	NSSize size;
	size.width  = [pdfImageRep pixelsWide] * resolutionLevel + leftMargin + rightMargin;
	size.height = [pdfImageRep pixelsHigh] * resolutionLevel + topMargin + bottomMargin;
	
	NSImage* image = [[[NSImage alloc] initWithSize:size] autorelease];
	[image lockFocus];
	[pdfImageRep drawInRect:NSMakeRect(leftMargin, topMargin, [pdfImageRep pixelsWide] * resolutionLevel, [pdfImageRep pixelsHigh] * resolutionLevel)];
	[image unlockFocus];
	
	// NSImage を TIFF 形式の NSBitmapImageRep に変換する
	NSBitmapImageRep *imageRep = [[[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]] autorelease];
	
	NSData *outputData;
	if([@"jpg" isEqualToString:extension])
	{
		NSDictionary *propJpeg = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithFloat: 0.9],
								  NSImageCompressionFactor,
								  nil];
		outputData = [imageRep representationUsingType:NSJPEGFileType properties:propJpeg];
	}
	else // png出力の場合
	{
		if(!transparentPngFlag)
		{
			imageRep = [self fillBackground:imageRep];
		}
		NSDictionary *propPng = [NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithFloat: 2.0],
								 NSImageCompressionFactor, nil];
		outputData = [imageRep representationUsingType:NSPNGFileType properties:propPng];
	}
	[outputData writeToFile:[tempdir stringByAppendingPathComponent:outputFileName] atomically: YES];

}

/*
- (int)eps2image:(NSString*)epsName outputFileName:(NSString*)outputFileName resolution:(int)resolution
{
	NSString* trimFileName = [NSString stringWithFormat:@"%@.trim.eps", epsName];
	NSString* extension = [[outputFileName pathExtension] lowercaseString];

	// まずはEPSファイルのバウンディングボックスを取得
	OGRegularExpression *regex = [OGRegularExpression regularExpressionWithString:@"^\\%\\%BoundingBox\\: (\\d+) (\\d+) (\\d+) (\\d+)$"]; // バウンディングボックス情報の正規表現
	OGRegularExpressionMatch *match;
	NSEnumerator *matchEnum;
	
	int leftbottom_x  = 0;
	int leftbottom_y  = 0;
	int righttop_x  = 0;
	int righttop_y  = 0;
	
	char line[MAX_LEN];
	FILE *fp;
	fp = fopen([[tempdir stringByAppendingPathComponent:epsName] cString], "r");
	
	while ((fgets(line, MAX_LEN - 1, fp)) != NULL) {
		matchEnum = [regex matchEnumeratorInString:[NSString stringWithCString:line]]; // 正規表現マッチを実行
		if((match = [matchEnum nextObject]) != nil)
		{
			leftbottom_x  = [[match substringAtIndex:1] intValue] - leftMargin / resolutionLevel;
			leftbottom_y  = [[match substringAtIndex:2] intValue] - bottomMargin / resolutionLevel;
			righttop_x  = [[match substringAtIndex:3] intValue] + rightMargin / resolutionLevel;
			righttop_y  = [[match substringAtIndex:4] intValue] + topMargin / resolutionLevel;
			break;
		}
	}
	fclose(fp);
	
	
	// 次にトリミングするためのEPSファイルを作成
	fp = fopen([[tempdir stringByAppendingPathComponent:trimFileName] cString], "w");
	fputs("/NumbDict countdictstack def\n", fp);
	fputs("1 dict begin\n", fp);
	fputs("/showpage {} def\n", fp);
	fputs("userdict begin\n", fp);
	fputs([[NSString stringWithFormat:@"%d.000000 %d.000000 translate\n", -leftbottom_x, -leftbottom_y] cString], fp);
	fputs("1.000000 1.000000 scale\n", fp);
	fputs("0.000000 0.000000 translate\n", fp);
	fputs([[NSString stringWithFormat:@"(%@) run\n", epsName] cString], fp);
	fputs("countdictstack NumbDict sub {end} repeat\n", fp);
	fputs("showpage\n", fp);
	fclose(fp);
	
	// 最後に目的の形式に変換
	NSString *device = @"jpeg";
	if([@"png" isEqualToString:extension])
	{
		device = transparentPngFlag ? @"pngalpha" : @"png256";
	}
	
	int status = [self execCommand:gsPath atDirectory:tempdir withArguments:
				  [NSArray arrayWithObjects:
				   @"-q",
				   [NSString stringWithFormat:@"-sDEVICE=%@", device],
				   [NSString stringWithFormat:@"-sOutputFile=%@", outputFileName],
				   @"-dNOPAUSE",
				   @"-dBATCH",
				   @"-dPDFFitPage",
				   [NSString stringWithFormat:@"-r%d", resolution],
				   [NSString stringWithFormat:@"-g%dx%d", (righttop_x - leftbottom_x) * resolutionLevel, (righttop_y - leftbottom_y) * resolutionLevel],
				   trimFileName,
				   nil]
						withStdout:nil];
	
	return status;
}
*/

- (bool)compileAndConvertTo:(NSString*)outputFilePath
{
	NSString* teXFilePath = [NSString stringWithFormat:@"%@.tex", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	NSString* dviFilePath = [NSString stringWithFormat:@"%@.dvi", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	NSString* pdfFilePath = [NSString stringWithFormat:@"%@.pdf", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	NSString* outputEpsFileName = [NSString stringWithFormat:@"%@.eps", tempFileBaseName];
	NSString* outputFileName = [outputFilePath lastPathComponent];
	NSString* extension = [[outputFilePath pathExtension] lowercaseString];
	
	// TeX→DVI
	if(![self tex2dvi:teXFilePath])
	{
		[controller showCompileError];
		return NO;
	}
	
	if(![fileManager fileExistsAtPath:dviFilePath])
	{
		[controller showExecError:@"platex"];
		return NO;
	}
	
	// DVI→PDF
	if(![self dvi2pdf:dviFilePath] || ![fileManager fileExistsAtPath:pdfFilePath])
	{
		[controller showExecError:@"dvipdfmx"];
		return NO;
	}
	
	if(([@"jpg" isEqualToString:extension] || [@"png" isEqualToString:extension]) && leaveTextFlag) // 文字化け対策を行わない jpg/png の場合，PDFから直接変換
	{
		[self pdf2image:pdfFilePath outputFileName:outputFileName];
	}
	else if([@"pdf" isEqualToString:extension] && leaveTextFlag) // 最終出力が文字埋め込み PDF の場合，EPSを経由しなくてよいので，pdfcrop で直接生成する。
	{
		[self pdfcrop:pdfFilePath outputFileName:outputFileName addMargin:YES];
	}
	else // EPS を経由する形式(.eps/アウトラインを取ったpdf / 文字化け対策 jpg,png )の場合
	{
		/*
		// PDF→EPS の変換の準備
		int resolution;
		 
		if([@"jpg" isEqualToString:extension] || [@"png" isEqualToString:extension])
		{
			resolution = 72 * resolutionLevel;
			outputEpsFileName = [NSString stringWithFormat:@"%@.eps", tempFileBaseName];
			
		}
		else // .eps/.pdf 出力の場合
		{ 
			resolution = 20016;
			outputEpsFileName = outputFileName;
		}
		*/

		int resolution = 20016;
		
		// PDF→EPS の変換の実行
		if(![self pdf2eps:[NSString stringWithFormat:@"%@.pdf", tempFileBaseName] outputEpsFileName:outputEpsFileName resolution:resolution] 
		   || ![fileManager fileExistsAtPath:[tempdir stringByAppendingPathComponent:outputEpsFileName]])
		{
			[controller showExecError:@"ghostscript"];
			return NO;
		}
		
		if([@"pdf" isEqualToString:extension]) // アウトラインを取ったPDFを作成する場合，EPSからPDFに戻す
		{
			[self eps2pdf:outputEpsFileName outputFileName:outputFileName];
		}
		else if([@"eps" isEqualToString:extension])  // 最終出力が EPS の場合，生成したEPSファイルの名前を最終出力ファイル名へ変更する
		{
			[fileManager movePath:[tempdir stringByAppendingPathComponent:outputEpsFileName] toPath:outputFileName handler:nil];
		}
		else if([@"jpg" isEqualToString:extension] || [@"png" isEqualToString:extension]) // 文字化け対策JPEG/PNG出力の場合，EPSをPDFに戻した上で，それをさらにJPEG/PNGに変換する
		{
			NSString* outlinedPdfFileName = [NSString stringWithFormat:@"%@.outline.pdf", tempFileBaseName];
			[self eps2pdf:outputEpsFileName outputFileName:outlinedPdfFileName]; // アウトラインを取ったEPSをPDFへ戻す
			[self pdf2image:[tempdir stringByAppendingPathComponent:outlinedPdfFileName] outputFileName:outputFileName]; // PDFを目的の画像ファイルへ変換
		}
		
		/*
		// 出力画像が JPEG または PNG の場合の EPS からの変換処理
		if([@"jpg" isEqualToString:extension] || [@"png" isEqualToString:extension])
		{
			if(![self eps2image:outputEpsFileName outputFileName:outputFileName resolution:resolution] 
			   || ![fileManager fileExistsAtPath:[tempdir stringByAppendingPathComponent:outputFileName]])
			{
				[controller showExecError:@"ghostscript"];
				return NO;
			}
		}
		*/
	}
	
	// 最終出力ファイルを目的地へコピー
	if([fileManager fileExistsAtPath:outputFilePath] && [fileManager removeFileAtPath:outputFilePath handler:nil]==NO)
	{
		[controller showCannotOverrideError:outputFilePath];
		return NO;
	}
	[fileManager copyPath:[tempdir stringByAppendingPathComponent:outputFileName] toPath:outputFilePath handler:nil];
	
	return YES;
}

- (bool)compileAndConvertWithCheckTo:(NSString*)outputFilePath
{
	bool status = YES;
	// 最初にプログラムの存在確認と出力ファイル形式確認
	if(![controller checkPlatexPath:platexPath dvipdfmxPath:dvipdfmxPath gsPath:gsPath])
	{
		status = NO;
	}
	
	NSString* extension = [[outputFilePath pathExtension] lowercaseString];
	
	if(![@"eps" isEqualToString:extension] && ![@"png" isEqualToString:extension] && ![@"jpg" isEqualToString:extension] && ![@"pdf" isEqualToString:extension])
	{
		[controller showExtensionError];
		status = NO;
	}
	
	if(status)
	{
		// 一連のコンパイル処理の開始準備
		[controller clearOutputTextView];
		if(showOutputWindowFlag)
		{
			[controller showOutputWindow];
		}
		[controller showMainWindow];
		
		// 一連のコンパイル処理を実行
		status = [self compileAndConvertTo:outputFilePath];
		
		// プレビュー処理
		if(status && previewFlag)
		{
			[[NSWorkspace sharedWorkspace] openFile:outputFilePath withApplication:@"Preview.app"];
		}
	}
	
	// 中間ファイルの削除
	if(deleteTmpFileFlag)
	{
		NSString* outputFileName = [outputFilePath lastPathComponent];
		NSString* basePath = [tempdir stringByAppendingPathComponent:tempFileBaseName];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.tex", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.dvi", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.log", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.aux", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.pdf", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.outline.pdf", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.eps", basePath] handler:nil];
		[fileManager removeFileAtPath:[NSString stringWithFormat:@"%@.eps.trim.pdf", basePath] handler:nil];
		[fileManager removeFileAtPath:[tempdir stringByAppendingPathComponent:outputFileName] handler:nil];
	}
	
	return status;
}

- (bool)compileAndConvertWithSource:(NSString*)texSourceStr outputFilePath:(NSString*)outputFilePath
{
	//TeX ソースを準備
	NSString* tempTeXFilePath = [NSString stringWithFormat:@"%@.tex", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	
	if(![self writeStringWithYenBackslashConverting:texSourceStr toFile:tempTeXFilePath])
	{
		[controller showFileGenerateError:tempTeXFilePath];
		return NO;
	}
	
	return [self compileAndConvertWithCheckTo:outputFilePath];
}

- (bool)compileAndConvertWithPreamble:(NSString*)preambleStr withBody:(NSString*)texBodyStr outputFilePath:(NSString*)outputFilePath
{
	// TeX ソースを用意
	NSString* texSourceStr = [NSString stringWithFormat:@"%@\n\\begin{document}\n%@\n\\end{document}", preambleStr, texBodyStr];
	return [self compileAndConvertWithSource:texSourceStr outputFilePath:outputFilePath];
}

- (bool)compileAndConvertWithInputPath:(NSString*)texSourcePath outputFilePath:(NSString*)outputFilePath
{
	NSString* tempTeXFilePath = [NSString stringWithFormat:@"%@.tex", [tempdir stringByAppendingPathComponent:tempFileBaseName]];
	if(![fileManager copyPath:texSourcePath toPath:tempTeXFilePath handler:nil])
	{
		[controller showFileGenerateError:tempTeXFilePath];
		return NO;
	}
	
	return [self compileAndConvertWithCheckTo:outputFilePath];
}


@end
