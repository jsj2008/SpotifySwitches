#ifndef HEADER
#define HEADER

NSString *const nsNotificationString = @"se.nosskirneh.sos/preferences.changed";
NSString *const nsDomainString = @"se.nosskirneh.sos";
NSString *const onlineNotification = @"se.nosskirneh.sos/online";
NSString *const offlineNotification = @"se.nosskirneh.sos/offline";
NSString *const offlineModeChanged = @"se.nosskirneh.sos/toggled";
NSString *const pathToPlist = @"/var/mobile/Library/Preferences/%@.plist";
NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:pathToPlist, nsDomainString]];


@interface SPCore : NSObject
- (void)setForcedOffline:(BOOL)arg;
@end


@interface SettingsSection : NSObject

@end


@interface SettingsViewController : UIViewController
@property (weak, nonatomic) NSArray<SettingsSection *> *sections;
@end


// Use this when you've solved the shared settings problem.
//@interface Adjust : NSObject
//- (void)setOfflineMode:(BOOL)arg;
//@end


@interface SPNavigationController : UIViewController

@end


@interface NSUserDefaults (Tweak_Category)
- (id)objectForKey:(NSString *)key inDomain:(NSString *)domain;
- (void)setObject:(id)value forKey:(NSString *)key inDomain:(NSString *)domain;
@end

#endif
