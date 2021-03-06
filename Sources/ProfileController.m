#import "ProfileController.h"
#import "NSDictionary-Extension.h"
#import "ControllerG.h"
#import "UtilityG.h"

#define MovedRowsType @"TeX2imgMovedRowsType"

@interface ProfileController()
@property (nonatomic, copy) NSMutableArray<Profile*> *profiles;
@property (nonatomic, copy) NSMutableArray<NSString*> *profileNames;
@property (nonatomic, strong) IBOutlet NSWindow *profilesWindow;
@property (nonatomic, strong) IBOutlet NSTableView *profilesTableView;
@property (nonatomic, strong) IBOutlet NSTextField *saveAsTextField;
@property (nonatomic, strong) IBOutlet ControllerG *controllerG;
@end

@implementation ProfileController
@synthesize profiles;
@synthesize profileNames;
@synthesize profilesWindow;
@synthesize profilesTableView;
@synthesize saveAsTextField;
@synthesize controllerG;

- (MutableProfile*)profileForName:(NSString*)profileName
{
    if (!profileNames) {
        return nil;
    }
	
	NSUInteger targetIndex = [profileNames indexOfObject:profileName];
	return (targetIndex == NSNotFound) ? nil : [MutableProfile dictionaryWithDictionary:profiles[targetIndex]];
}

- (void)loadProfilesFromPlist
{
	profileNames = [NSMutableArray<NSString*> arrayWithArray:[NSUserDefaults.standardUserDefaults arrayForKey:ProfileNamesKey]];
	profiles =  [NSMutableArray<Profile*> arrayWithArray:[NSUserDefaults.standardUserDefaults arrayForKey:ProfilesKey]];
}

- (void)initProfiles
{
	profileNames = [NSMutableArray<NSString*> array];
	profiles = [NSMutableArray<Profile*> array];
}

- (void)removeProfileForName:(NSString*)profileName
{
	NSUInteger targetIndex = [profileNames indexOfObject:profileName];
    if (targetIndex == NSNotFound) {
        return;
    }
	[profileNames removeObjectAtIndex:targetIndex];
	[profiles removeObjectAtIndex:targetIndex];
}

- (void)updateProfile:(Profile*)aProfile forName:(NSString*)profileName
{
	NSUInteger targetIndex = [profileNames indexOfObject:profileName];
	if (targetIndex == NSNotFound) {
		[profileNames addObject:profileName];
		[profiles addObject:aProfile];
	} else {
		profileNames[targetIndex] = profileName;
		profiles[targetIndex] = aProfile;
	}
}

- (void)saveProfiles
{
	NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
	[userDefaults setObject:profileNames forKey:ProfileNamesKey];
	[userDefaults setObject:profiles forKey:ProfilesKey];
	[userDefaults synchronize];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView
{
	return profileNames.count;
}

- (id)tableView:(NSTableView*)aTableView objectValueForTableColumn:(NSTableColumn*)aTableColumn row:(NSInteger)rowIndex
{
	return profileNames[rowIndex];
}


- (IBAction)addProfile:(id)sender
{
	NSString *newProfileName = saveAsTextField.stringValue;
	
	if ([newProfileName isEqualToString:@""]) {
		NSBeep();
        runErrorPanel(localizedString(@"emptyProfileNameErrMsg"));
	} else {
		NSUInteger aIndex = [profileNames indexOfObject:newProfileName];
		if (aIndex == NSNotFound) {
			[self updateProfile:[controllerG currentProfile] forName:newProfileName];
			saveAsTextField.stringValue = @"";
			[profilesWindow makeFirstResponder:saveAsTextField]; // フォーカスを入力欄に
		} else {
			if (runConfirmPanel(localizedString(@"profileOverwriteMsg"))) {
				[self updateProfile:[controllerG currentProfile] forName:newProfileName];
				saveAsTextField.stringValue = @"";
			} else {
				[profilesWindow makeFirstResponder:saveAsTextField]; // フォーカスを入力欄に
			}
		}
		[profilesTableView reloadData];
	}
    
}

- (IBAction)loadProfile:(id)sender
{
    NSInteger selectedIndex = profilesTableView.selectedRow;
    if (selectedIndex == -1) {
        return;
    }
	
	[controllerG adoptProfile:profiles[selectedIndex]];
	[profilesWindow close];
}

- (IBAction)removeProfile:(id)sender
{
    NSInteger selectedIndex = profilesTableView.selectedRow;
    if (selectedIndex == -1) {
        return;
    }
	
	[profileNames removeObjectAtIndex:selectedIndex];
	[profiles removeObjectAtIndex:selectedIndex];
	
	[profilesTableView reloadData];
	
}

- (void)awakeFromNib
{
	profilesTableView.target = self;
	profilesTableView.action = @selector(setSelectedProfileName:);
	profilesTableView.doubleAction = @selector(loadProfile:);

	[profilesTableView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
	[profilesTableView registerForDraggedTypes:@[MovedRowsType]];
}

- (IBAction)setSelectedProfileName:(id)sender
{
	NSInteger selectedIndex = profilesTableView.selectedRow;
    if (selectedIndex == -1) {
        return;
    }

	saveAsTextField.stringValue = profileNames[selectedIndex];
}

- (void)showProfileWindow
{
	[profilesWindow makeKeyAndOrderFront:nil];
}

#pragma mark - ドラッグ＆ドロップによる行の並べ替え関連
- (BOOL)tableView:(NSTableView*)aTableView
    writeRowsWithIndexes:(NSIndexSet*)rowIndexes
     toPasteboard:(NSPasteboard*)pboard
{
	// declare our own pasteboard types
    NSArray<NSString*> *typesArray = @[MovedRowsType];
	[pboard declareTypes:typesArray owner:self];
	
    // add rows array for local move
	NSData *rowIndexesArchive = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard setData:rowIndexesArchive forType:MovedRowsType];
	
    return YES;
}


- (NSDragOperation)tableView:(NSTableView*)aTableView 
				validateDrop:(id<NSDraggingInfo>)info
				 proposedRow:(NSInteger)row 
	   proposedDropOperation:(NSTableViewDropOperation)op
{
	// 行間へのドロップは許すが，行自体へのドロップ(NSTableViewDropOn)は許さない
    [aTableView setDropRow:row dropOperation:NSTableViewDropAbove];

    if (info.draggingSource == profilesTableView) {
		return NSDragOperationMove;
    }
	return NSDragOperationNone;
}

- (NSIndexSet*)moveObjectsOf:(NSMutableArray*)anArray
				 fromIndexes:(NSIndexSet*)fromIndexSet 
					 toIndex:(NSInteger)insertIndex
{	
	// If any of the removed objects come before the insertion index,
	// we need to decrement the index appropriately
	NSUInteger adjustedInsertIndex = insertIndex - [fromIndexSet countOfIndexesInRange:(NSRange){0, insertIndex}];
	NSRange destinationRange = NSMakeRange(adjustedInsertIndex, fromIndexSet.count);
	NSIndexSet *destinationIndexes = [NSIndexSet indexSetWithIndexesInRange:destinationRange];
	
	NSArray *objectsToMove = [anArray objectsAtIndexes:fromIndexSet];
	[anArray removeObjectsAtIndexes:fromIndexSet];	
	[anArray insertObjects:objectsToMove atIndexes:destinationIndexes];

	return destinationIndexes;
	
}

- (BOOL)tableView:(NSTableView*)aTableView
	   acceptDrop:(id<NSDraggingInfo>)info
			  row:(NSInteger)insertionRow
	dropOperation:(NSTableViewDropOperation)op
{
    if (insertionRow < 0) {
		insertionRow = 0;
	}
	// if drag source is self, it's a move unless the Option key is pressed
    if (info.draggingSource == profilesTableView) {
		NSEvent *currentEvent = [NSApp currentEvent];
		NSUInteger optionKeyPressed = currentEvent.modifierFlags & NSAlternateKeyMask;
		
		if (optionKeyPressed == 0) {
			NSData *rowsData = [info.draggingPasteboard dataForType:MovedRowsType];
			NSIndexSet *indexSet = [NSKeyedUnarchiver unarchiveObjectWithData:rowsData];
			NSIndexSet *newIndexes = [self moveObjectsOf:profileNames fromIndexes:indexSet toIndex:insertionRow];
			[self moveObjectsOf:profiles fromIndexes:indexSet toIndex:insertionRow];
			[aTableView selectRowIndexes:newIndexes byExtendingSelection:NO]; // 今動かしたばかりの行を選択する
			[aTableView reloadData];
			return YES;
		}
    }
	
    return NO;
}
#pragma mark -

@end
