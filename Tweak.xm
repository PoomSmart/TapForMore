/*
*	TapForMore (SwipeForMore alternative for earlier OS)
*	Made possible by DTActionSheet, thanks to Cocoanetics
*
*	Long tap package cell to activate options
*	Enjoy
*
*/

#import <Cydia/FilteredPackageListController.h>
#import <Cydia/CYPackageController.h>
#import <Cydia/ConfirmationController.h>
#import <Cydia/ProgressController.h>
#import <Cydia/Cydia-Class.h>
#import <notify.h>
#import "../PSPrefs.x"
#import "../PS.h"
#import "DTActionSheet.h"

@interface FilteredPackageListController () <UIActionSheetDelegate, UIGestureRecognizerDelegate>
- (UITableView *)tableView;
@end

BOOL enabled;
BOOL noConfirm;
BOOL autoDismiss;
BOOL withIcon;

BOOL should;
BOOL queue;
BOOL isQueuing;

NSString *tweakIdentifier = @"com.PS.TapForMore";
NSString *format = @"%@ %@";

HaveCallback()
{
	GetPrefs()
	GetBool(enabled, @"enabled", YES)
	GetBool(noConfirm, @"confirm", NO)
	GetBool(autoDismiss, @"autoDismiss", YES)
	GetBool(withIcon, @"withIcon", NO)
}

CYPackageController *cy;

%hook CYPackageController

- (id)initWithDatabase:(Database *)database forPackage:(Package *)package withReferrer:(id)referrer
{
	self = %orig;
	cy = self;
	return self;
}

%end

%hook Cydia

- (void)reloadDataWithInvocation:(NSInvocation *)invocation { isQueuing = NO; %orig; }
- (void)confirmWithNavigationController:(UINavigationController *)navigation { isQueuing = NO; %orig; }
- (void)cancelAndClear:(bool)clear { isQueuing = !clear; %orig; }

%end

%hook CydiaTabBarController

- (void)presentViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion
{
	if ([vc isKindOfClass:[UINavigationController class]]) {
		if ([((UINavigationController *)vc).topViewController class] == NSClassFromString(@"ConfirmationController")) {
			void (^block)(void) = ^(void) {
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.16*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					if (should && !isQueuing)
						[(ConfirmationController *)(((UINavigationController *)vc).topViewController) confirmButtonClicked];
					else if (queue) {
						// queue a package
						[(ConfirmationController *)(((UINavigationController *)vc).topViewController) _doContinue];
						queue = NO;
					}
					if (completion)
						completion();
				});
			};
			%orig(vc, animated, block);
			return;
		}
	}
	%orig;
}

%end

static _finline void _UpdateExternalStatus(uint64_t newStatus) {
    int notify_token;
    if (notify_register_check("com.saurik.Cydia.status", &notify_token) == NOTIFY_STATUS_OK) {
        notify_set_state(notify_token, newStatus);
        notify_cancel(notify_token);
    }
    notify_post("com.saurik.Cydia.status");
}

%hook ProgressController

- (void)invoke:(NSInvocation *)invocation withTitle:(NSString *)title
{
	%orig;
	if (should) {
		should = NO;
		uint64_t status = -1;
		int notify_token;
		if (notify_register_check("com.saurik.Cydia.status", &notify_token) == NOTIFY_STATUS_OK) {
			notify_get_state(notify_token, &status);
			notify_cancel(notify_token);
		}
		if (status == 0 && autoDismiss) {
			Cydia *delegate = (Cydia *)[UIApplication sharedApplication];
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.22*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
				_UpdateExternalStatus(0);
				[delegate returnToCydia];
				[[self.navigationController parentOrPresentingViewController] dismissModalViewControllerAnimated:YES];
			});
		}
	}
}

%end

NSString *itsString(NSString *key, NSString *value)
{
	// ¯\_(ツ)_/¯
	return [[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/iTunesStore.framework"] localizedStringForKey:key value:value table:nil];
}

NSString *combine(NSString *icon, NSString *text)
{
	if (withIcon)
		return [NSString stringWithFormat:@"%@ %@", icon, text];
	return text;
}

NSString *_buy = nil;

NSString *buyString()
{
	return withIcon ? @"💳" : _buy ? _buy : _buy = itsString(@"BUY", @"Buy");
}

NSString *installString()
{
	return combine(@"↓", UCLocalize("INSTALL"));
}

NSString *reinstallString()
{
	return combine(@"↺", UCLocalize("REINSTALL"));
}

NSString *upgradeString()
{
	return combine(@"↑", UCLocalize("UPGRADE"));
}

NSString *removeString()
{
	return combine(@"╳", UCLocalize("REMOVE"));
}

NSString *queueString()
{
	return combine(@"Q", UCLocalize("QUEUE"));
}

NSString *clearString()
{
	return combine(@"⌧", UCLocalize("CLEAR"));
}

NSString *downgradeString()
{
	return combine(@"⇵", UCLocalize("DOWNGRADE"));
}

NSString *normalizedQueue(NSString *text)
{
	NSArray *subs = [text componentsSeparatedByString:@" "];
	if (subs.count == 4)
		return [NSString stringWithFormat:@"%@%@ %@ %@", subs[0], subs[2], subs[1], subs[3]];
	return text;
}

%hook FilteredPackageListController

%new
- (UITableView *)tableView
{
	return (UITableView *)self.view.subviews[0];
}

- (void)loadView
{
	%orig;
	UILongPressGestureRecognizer *gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tfm_handleLongPress:)];
	gesture.minimumPressDuration = 0.32;
	gesture.delegate = self;
	[self.tableView addGestureRecognizer:gesture];
	[gesture release];
}

static void configureSheetForIndexPath(PackageListController *self, DTActionSheet *sheet, NSIndexPath *indexPath_)
{
	Package *package = [self packageAtIndexPath:indexPath_];
	sheet.title = package.name;
	Cydia *delegate = (Cydia *)[UIApplication sharedApplication];
	BOOL installed = ![package uninstalled];
	BOOL upgradable = [package upgradableAndEssential:NO];
	BOOL isQueue = [package mode] != nil;
	bool commercial = [package isCommercial];
	if (installed) {
		// remove
		[sheet addDestructiveButtonWithTitle:removeString() block:^{
			should = noConfirm;
			[delegate removePackage:package];
		}];
	}
	NSString *installTitle = installed ? (upgradable ? upgradeString() : reinstallString()) : (commercial ? buyString() : installString());
	if (!isQueue)	{
		// install or buy
		[sheet addButtonWithTitle:installTitle block:^{
			should = noConfirm && (!commercial || (commercial && installed));
			if (commercial && !installed) {
				[self didSelectPackage:package];
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
					[cy customButtonClicked];
				});	
			}
			else
				[delegate installPackage:package];
		}];
	}
	if (installed && !isQueue) {
		// queue reinstall action
		NSString *queueReinstallTitle = normalizedQueue([NSString stringWithFormat:format, queueString(), installTitle]);
		[sheet addButtonWithTitle:queueReinstallTitle block:^{
			should = NO;
			queue = autoDismiss;
			[delegate installPackage:package];
		}];
	}
	if (isQueue) {
		// a package is currently in clear state
		[sheet addButtonWithTitle:clearString() block:^{
			should = NO;
			queue = isQueuing;
			[delegate clearPackage:package];
		}];
	} else {
		// queue remove/install
		NSString *queueTitle = normalizedQueue([NSString stringWithFormat:format, queueString(), (installed ? removeString() : installTitle)]);
		[sheet addButtonWithTitle:queueTitle block:^{
			should = NO;
			queue = autoDismiss;
			if (installed)
				[delegate removePackage:package];
			else
				[delegate installPackage:package];
		}];
	}
	if ([package downgrades].count > 0)	{
		NSString *downgradeTitle = downgradeString();
		[sheet addButtonWithTitle:downgradeTitle block:^{
			should = NO;
			queue = NO;
			[self didSelectPackage:package];
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.9*NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
				[cy _clickButtonWithName:@"DOWNGRADE"];
			});
		}];
	}
	[sheet addCancelButtonWithTitle:UCLocalize("CANCEL") block:^{}];
}

%new
- (void)tfm_handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		CGPoint p = [gestureRecognizer locationInView:self.tableView];
		NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
		if (indexPath) {
			UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
			if (cell.isHighlighted) {
				DTActionSheet *sheet = [[[DTActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil] autorelease];
				configureSheetForIndexPath(self, sheet, indexPath);
				[sheet showInView:self.tableView];
			}
		}
	}
}

%end

%ctor
{
	HaveObserver()
	callback();
	if (enabled) {
		%init;
	}
}