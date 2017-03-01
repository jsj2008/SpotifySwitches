#import "Connectify.h"

@implementation Connectify

UIActionSheet *connectSheet;
NSMutableArray<NSString *> *devices;
NSMutableArray *titles;
NSString *activeDevice;

+ (void)load {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"])
        [(LAActivator *)[%c(LAActivator) sharedInstance] registerListener:[self new] forName:@"se.nosskirneh.connectify"];
    [pool release];
}

- (id)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectStartNotificationReceived:) name:@"Connectify.start" object:nil];
    }
    // Init settings file
    preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath];
    if (!preferences) preferences = [[NSMutableDictionary alloc] init];
    
    return self;
}

// Called when the user-defined action is recognized, shows selection sheet
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
    [event setHandled:YES];
    
    HBLogDebug(@"Listener received call to (activator:receiveEvent:)");
    [self connectStartNotificationReceived:nil];
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
    HBLogDebug(@"Listener received call to (activator:abortEvent:)");
    [self dismiss];
}

- (void)activator:(LAActivator *)activator otherListenerDidHandleEvent:(LAEvent *)event {
    HBLogDebug(@"Listener received call to (activator:otherListenerDidHandleEvent:)");
    [self dismiss];
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event {
    HBLogDebug(@"Listener received call to (activator:receiveDeactivateEvent:)");
    [self dismiss];
}

// Restricts action to only be paired with other non-modal-ui actions
- (NSArray *)activator:(LAActivator *)activator requiresExclusiveAssignmentGroupsForListenerName:(NSString *)listenerName {
    return @[@"modal-ui"];
}

- (void)connectStartNotificationReceived:(NSNotification *)notification {
    if (connectSheet) {
        HBLogDebug(@"Already presenting an action sheet, so we'll ignore this subsequent call");
        return;
    }

    // Implement this later
    SBApplication* app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:spotifyBundleIdentifier];
    HBLogDebug(@"%@", app);
    int pid = [app pid];
    
    connectSheet = [[UIActionSheet alloc] initWithTitle:@"Connectify\nDevices" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    if (pid >= 0) { // Spotify is running
        // Update preferences
        preferences  = [[NSMutableDictionary alloc] initWithContentsOfFile:prefPath];
        deviceNames  = [preferences objectForKey:devicesKey];
        activeDevice = [preferences objectForKey:activeDeviceKey];
        titles = [[NSMutableArray alloc] initWithCapacity:deviceNames.count+1];
        
        for (int i = 0; i < deviceNames.count; i++) {
            if ([activeDevice isEqualToString:deviceNames[i]]) {
                [titles addObject:[@"●  " stringByAppendingString:deviceNames[i]]];
            } else {
                [titles addObject:deviceNames[i]];
            }
            [connectSheet addButtonWithTitle:titles[i]];
        }
    } else {
        connectSheet.destructiveButtonIndex = [connectSheet addButtonWithTitle:@"Launch Spotify"];
    }

    connectSheet.cancelButtonIndex = [connectSheet addButtonWithTitle:@"Cancel"];
    
    [connectSheet showInView:[UIApplication sharedApplication].keyWindow];
    HBLogDebug(@"Notification received, presented action sheet (%@) from window: %@", connectSheet, [UIApplication sharedApplication].keyWindow);
}

- (void)dismiss {
    if (connectSheet) {
        [connectSheet dismissWithClickedButtonIndex:connectSheet.cancelButtonIndex animated:YES];
    } else {
        HBLogDebug(@"Cannot dismiss non-existent action sheet");
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    HBLogDebug(@"actionSheet:<%@>clickedButtonAtIndex:<%i>, buttonTitle:%@", actionSheet, (int)buttonIndex, buttonTitle);
    
    if (buttonIndex < 0 || [buttonTitle isEqualToString:@"Cancel"]) { // Cancel
        HBLogDebug(@"Dismissing action sheet after cancel button press");
    } else if ([buttonTitle isEqualToString:@"Launch Spotify"]) { // Launch Spotify
        HBLogDebug(@"Trying to launch Spotify");
        [[%c(UIApplication) sharedApplication] launchApplicationWithIdentifier:spotifyBundleIdentifier suspended:NO];
    } else {
        NSString *selectedDeviceName = deviceNames[[titles indexOfObject:buttonTitle]];
        
        if ([activeDevice isEqualToString:selectedDeviceName]) {
            HBLogDebug(@"Trying to disconnected from: %@", selectedDeviceName);
            [preferences setObject:@"" forKey:activeDeviceKey];
        } else {
            HBLogDebug(@"Trying to connect to: %@", selectedDeviceName);
            [preferences setObject:selectedDeviceName forKey:activeDeviceKey];
        }
        
        // Save to .plist
        if (![preferences writeToFile:prefPath atomically:YES]) {
            HBLogError(@"Could not save preferences!");
        }
        // Send notification that device was changed
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)doChangeConnectDeviceNotification, NULL, NULL, YES);
    }
    devices = nil;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    connectSheet = nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
//    [devices release];
//    [titles release];
    [connectSheet release];
    
    [super dealloc];
}

@end
