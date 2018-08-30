#import "JFTHCommonHeaders.h"
#import "JFTHiOSHeaders.h"
#import "JFTHRingtoneImporter.h"
#import "JFTHConstants.h"

#import <version.h>
// TODO: Add ringtone maker (or applist)
#pragma mark - Constants and preferences

BOOL kEnabled;
BOOL kDebugLogging;

/* TLToneManager:
 -(BOOL)toneWithIdentifierIsValid:(id)arg1 ;
 does identifier arg1 exist? (is it imported?)
 
 -(void)removeImportedToneWithIdentifier:(id)arg1 ;
 remove tone with identifier
 
 -(void)importTone:(id)arg1 metadata:(id)arg2 completionBlock:(BLOCK)arg3 ;
arg1 (NSData) ringtone
arg2 (NSMutable?Dictionary) keys="Name","Total Time","Purchased"=false,"Protected Content"=false
arg3 (code block) receives arguments? probably toneidentifier that TLToneManager set for the imported tone.
 
 */



HBPreferences *preferences;


#pragma mark - IOS 11
// -------- IOS 11 ---------
%group IOS11

#pragma mark - Preferences hook IOS 11
%hook PreferencesAppController
- (_Bool)application:(id)arg1 didFinishLaunchingWithOptions:(id)arg2 {
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Preferences"]) {
        DDLogVerbose(@"{\"Hooks\":\"didFinishLaunching called\"}");
        //[self performSelector:@selector(doImportRingtones)];
    }
    return %orig;
}

- (void)applicationWillEnterForeground:(id)arg1 {
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Preferences"]) {
        DDLogVerbose(@"{\"Hooks\":\"applicationWillEnterForeground called\"}");
        //[self performSelector:@selector(doImportRingtones)];
    }
    return %orig;
}

%new
- (void)doImportRingtones {
    DDLogInfo(@"{\"Hooks\":\"In preferences\"}");
    if (!kEnabled) {
        DDLogInfo(@"{\"Hooks\":\"in preferences, Disabled\"}");
        return;
    }
    DDLogInfo(@"{\"Hooks\":\"in preferences, Enabled\"}");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //We're in preferences app, lets look for new ringtones to import
        JFTHRingtoneImporter *importer = [[JFTHRingtoneImporter alloc] init];
        
        //Apps to look for ringtones in (in Documents folder)
        NSMutableArray *apps = [[NSMutableArray alloc] init];
        [apps addObject:@"com.908.AudikoFree"];
        [apps addObject:@"com.zedge.Zedge"];
        [apps addObject:@"com.908.Audiko"];
        
        for (NSString *app in apps) {
            [importer getRingtoneFilesFromApp:app];
        }
        [apps release];
        
        //Found something new to import?
        if ([importer shouldImportRingtones]) {
            [importer importNewRingtones];
        }
        // imported something?
        if ([importer importedCount] > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                DDLogDebug(@"{\"Hooks\":\"in preferences background thread, trying to reload tones\"}");
                
                if (NSClassFromString(@"TLToneManager")) {
                    
                    DDLogDebug(@"{\"Hooks\":\"in preferences background thread, TLTonemanager loaded, reloading tones\"}");

                    if ([[%c(TLToneManager) sharedToneManager] respondsToSelector:@selector(_reloadTonesAfterExternalChange)])
                        [[%c(TLToneManager) sharedToneManager] _reloadTonesAfterExternalChange]; // IOS 11
                }
            });
        }
        [importer release];
    });
}

%end
#pragma mark - TLToneManager IOS 11
%hook TLToneManager

 -(void)importTone:(id)arg1 metadata:(id)arg2 completionBlock:(id)arg3block {
     DDLogError(@"importTone called! ");
     DDLogError(@"arg1(NSDATA?): %@",[arg1 class]);
     DDLogError(@"arg2(NSDictionary?) %@",arg2);
     DDLogError(@"arg3(__Block): %@",arg3block);
     
     void (^myBlock)() = ^() {
         DDLogError(@"MY BLOCK WAS CALLED OMG OMG !!");
         //DDLogError(@"MY BLOCK param1: %@ param2: %@",[(id)p1 class],[(id)p2 class]);
         //DDLogError(@"MY BLOCK param1: %@ param2: %@",p1,p2);
         DDLogError(@"MY BLOCK returns: %@",arg3block());
     };
     %orig(arg1,arg2,myBlock);
     
}
%end

%end

#pragma mark - IOS 10
//------- IOS 10 ---------
%group IOS10
#pragma mark - Preferences hook IOS 10
%hook PreferencesAppController
- (_Bool)application:(id)arg1 didFinishLaunchingWithOptions:(id)arg2 {
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Preferences"]) {
        //[self performSelector:@selector(doImportRingtones)];
    }
    return %orig;
}

- (void)applicationWillEnterForeground:(id)arg1 {
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Preferences"]) {
        //[self performSelector:@selector(doImportRingtones)];
    }
    return %orig;
}

%new
- (void)doImportRingtones {
    DDLogInfo(@"{\"Hooks\":\"In preferences\"}");
    if (!kEnabled) {
        DDLogInfo(@"{\"Hooks\":\"in preferences, Disabled\"}");
        return;
    }
    DDLogInfo(@"{\"Hooks\":\"in preferences, Enabled\"}");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //We're in preferences app, lets look for new ringtones to import
        JFTHRingtoneImporter *importer = [[JFTHRingtoneImporter alloc] init];
        
        //Apps to look for ringtones in (in Documents folder)
        NSMutableArray *apps = [[NSMutableArray alloc] init];
        [apps addObject:@"com.908.AudikoFree"];
        [apps addObject:@"com.zedge.Zedge"];
        [apps addObject:@"com.908.Audiko"];
        
        for (NSString *app in apps) {
            [importer getRingtoneFilesFromApp:app];
        }
        [apps release];
        
        //Found something new to import?
        if ([importer shouldImportRingtones]) {
            [importer importNewRingtones];
        }
        // imported something?
        if ([importer importedCount] > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                DDLogDebug(@"{\"Hooks\":\"in preferences background thread, trying to reload tones\"}");
                
                if (NSClassFromString(@"TLToneManager")) {
                    
                    DDLogDebug(@"{\"Hooks\":\"in preferences background thread, TLTonemanager loaded, reloading tones\"}");

                    if ([[%c(TLToneManager) sharedToneManager] respondsToSelector:@selector(_reloadITunesRingtonesAfterExternalChange)])
                        [[%c(TLToneManager) sharedToneManager] _reloadITunesRingtonesAfterExternalChange]; // IOS 10
                }
            });
        }
        [importer release];
    });
}

%end

%end

/*
HBPreferencesValueChangeCallback updateRingtonePlist = ^(NSString *key, id<NSCopying> _Nullable newValue) {
    NSLog(@"{\"PrefValueChangeCallback\":\"Called in bundle: %@\"}", [[NSBundle mainBundle] bundleIdentifier]);
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Preferences"]) { // ||
        //[[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {
        // only run in springboard or preferences
        
        BOOL value = [[(NSNumber *)newValue copy] boolValue];
        DDLogDebug(@"{\"Preferences\":\"Notification received for key:%@ with value:%d\"}",key,value);

        if ([key isEqualToString:@"kWriteITunesRingtonePlist"]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[[JFTHRingtoneDataController alloc] init] syncPlists:value];
            });
        }
    }
};*/

extern NSString *const HBPreferencesDidChangeNotification;
NSSet *_ringtonesImported;

#pragma mark - Constructor
//------------- Constructor ------------
%ctor {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    NSLog(@"{\"Constructor\":\"Loaded in bundle: %@\"}", bundleID);
    
    //if ([bundleID isEqualToString:@"com.apple.Preferences"]) {

        [bundleID release];
        
        preferences = [[HBPreferences alloc] initWithIdentifier:@"fi.flodin.tonehelper"];
        [preferences registerBool:&kDebugLogging default:NO forKey:@"kDebugLogging"];
        [preferences registerBool:&kEnabled default:NO forKey:@"kEnabled"];
        //[preferences registerBool:&kWriteITunesRingtonePlist default:NO forKey:@"kWriteITunesRingtonePlist"];
        
        // TESTING
        [preferences registerObject:&_ringtonesImported default:[NSSet set] forKey:@"Ringtones"];
        
        
        
        /*if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Preferences"]) {
            [preferences registerPreferenceChangeBlock:(HBPreferencesValueChangeCallback)updateRingtonePlist forKey:@"kWriteITunesRingtonePlist"];
        }*/

        if (kDebugLogging) {
            
            LogglyFields *logglyFields = [[LogglyFields alloc] init];
            [logglyFields setAppversion:@"0.4.0"];
            
            [logglyFields setUserid:[[[UIDevice currentDevice] identifierForVendor] UUIDString]];
            
            LogglyLogger *logglyLogger = [[LogglyLogger alloc] init];
            [logglyLogger setLogFormatter:[[LogglyFormatter alloc] initWithLogglyFieldsDelegate:logglyFields]];
            logglyLogger.logglyKey = @"f962c4f9-899b-4d18-8f84-1da5d19e1184";
            
            logglyLogger.saveInterval = 600;
            
            [DDLog addLogger:logglyLogger];
            [DDLog addLogger:[DDASLLogger sharedInstance]];
            [logglyFields release];
            [logglyLogger release];
            
        }
        
        [preferences release];
        
        DDLogInfo(@"{\"Constructor\":\"Trying to initialize ToneHelper in bundleid: %@\"}",[[NSBundle mainBundle] bundleIdentifier]);
        if (!NSClassFromString(@"TLToneManager")) {
            DDLogInfo(@"{\"Constructor\":\"TLToneManager missing, loading framework\"}");
            dlopen("/System/Library/PrivateFrameworks/ToneLibrary.framework/ToneLibrary", RTLD_LAZY);
        }
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0) {
            DDLogInfo(@"{\"Constructor\":\"Init IOS 11\"}");
            %init(IOS11);
        } else {
            DDLogInfo(@"{\"Constructor\":\"Init IOS 10\"}");
            %init(IOS10);
        }

    //}
}
