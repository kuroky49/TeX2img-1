#import <stdarg.h>
#import "Utility.h"
#ifndef TeX2img_UtilityG_h
#define TeX2img_UtilityG_h

#define localizedString(str) (NSLocalizedString(str, nil))

void runOkPanel(NSString *title, NSString *message, ...);
void runErrorPanel(NSString *message, ...);
void runWarningPanel(NSString *message, ...);
BOOL runConfirmPanel(NSString *message, ...);
BOOL isJapaneseLanguage(void);

#endif
