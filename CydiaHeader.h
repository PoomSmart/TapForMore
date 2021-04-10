#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Package : NSObject
- (id)mode;
- (NSString *)name;
- (bool)isCommercial;
- (bool)installed;
- (bool)uninstalled;
- (bool)upgradableAndEssential:(bool)arg1;
- (NSArray <Package *> *)downgrades;
@end

@interface Cydia : UIApplication
- (void)installPackage:(Package *)package;
- (void)removePackage:(Package *)package;
- (void)clearPackage:(Package *)package;
- (void)returnToCydia;
@end

@interface Database : NSObject
@end

@interface CyteViewController : UIViewController
@end

@interface CyteTabBarController : UITabBarController
@end

@interface CyteWebViewController : CyteViewController <UIWebViewDelegate>
- (void)customButtonClicked;
@end

@interface CydiaWebViewController : CyteWebViewController
@end

@interface CYPackageController : CydiaWebViewController <UIActionSheetDelegate>
- (void)_clickButtonWithName:(NSString *)name;
@end

@interface ProgressController : CydiaWebViewController
@end

@interface ConfirmationController : CydiaWebViewController
- (void)_doContinue;
- (void)confirmButtonClicked;
@end

@interface PackageListController : CyteViewController <UITableViewDataSource, UITableViewDelegate>
- (void)didSelectPackage:(Package *)package;
- (Package *)packageAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface CydiaTabBarController : CyteTabBarController <UITabBarControllerDelegate>
@end

@interface FilteredPackageListController : PackageListController
@end

@interface UINavigationController (Cydia)
- (UIViewController *)parentOrPresentingViewController;
@end

@interface FilteredPackageListController () <UIActionSheetDelegate, UIGestureRecognizerDelegate>
- (UITableView *)tableView;
@end