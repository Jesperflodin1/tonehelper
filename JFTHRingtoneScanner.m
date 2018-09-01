#import "JFTHRingtoneScanner.h"
#import "JFTHRingtoneDataController.h"
#import "JFTHCommonHeaders.h"
#import "JFTHiOSHeaders.h"

//For md5 calculations
#include "FileHash.h"

//BOOL kWriteITunesRingtonePlist;

extern NSString *const HBPreferencesDidChangeNotification;

@interface JFTHRingtoneScanner () {
    NSMutableDictionary *_ringtonesToImport;
    BOOL _shouldImportRingtones;
    
    HBPreferences *preferences;
}

@end

@implementation JFTHRingtoneScanner

#pragma mark - Init methods
- (instancetype)init {
    if (self = [super init]) {
        DDLogInfo(@"{\"Ringtone Import\":\"Init\"}");
        if (!preferences) {
            preferences = [[HBPreferences alloc] initWithIdentifier:@"fi.flodin.tonehelper"];
            DDLogWarn(@"{\"Preferences\":\"Initializing preferences in importer.\"}");
        }
        _ringtoneDataController = [JFTHRingtoneDataController new];
        _ringtonesToImport = [NSMutableDictionary dictionary];
        _shouldImportRingtones = NO;
        self.importedCount = 0;
    }
    return self;
}

#pragma mark - Search app method
- (void)importNewRingtonesFromSubfoldersInApps:(NSDictionary *)apps {
    for (NSString *bundleID in apps) {
        [self _getNewRingtoneFilesFromApp:bundleID withSubfolder:[apps objectForKey:bundleID]];
    }
}
- (void)_getNewRingtoneFilesFromApp:(NSString *)bundleID withSubfolder:(NSString *)subfolder {
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    NSString *appDirectory;

    FBApplicationInfo *appInfo = [LSApplicationProxy applicationProxyForIdentifier:bundleID];
    appDirectory = [appInfo.dataContainerURL.path stringByAppendingPathComponent:subfolder];
    DDLogInfo(@"{\"Ringtone Import\":\"listing app folder for bundle: %@\"}",bundleID);

    NSArray *appDirFiles = [localFileManager contentsOfDirectoryAtPath:appDirectory error:nil];
    
    DDLogInfo(@"{\"Ringtone Import\":\"Found these files: %@\"}", appDirFiles);
    NSMutableArray *m4rFiles = [[NSMutableArray alloc] init];
    
    if (!appDirFiles) // App unavailable or folder unavailable, not adding
        return;
    
    DDLogDebug(@"{\"Ringtone Import\":\"App folder available!\"}");

    if (!([appDirFiles count] > 0)) // Nothing to import for this app
        return;
    
    DDLogInfo(@"{\"Ringtone Import\":\"Found %lu files\"}", (unsigned long)[appDirFiles count]);

    for (NSString *file in appDirFiles) {
        if ([[file pathExtension] isEqualToString: @"m4r"]) {
            
            //NSString *baseName = [JFTHRingtoneDataController createNameFromFile:file];
            // Check if ringtone already exists
            if ([_ringtoneDataController isImportedRingtoneWithFilePath:[appDirectory stringByAppendingPathComponent:file]]) {
                continue;
            }
            
            /*if ([_ringtoneDataController isImportedRingtoneWithHash:[FileHash md5HashOfFileAtPath:[appDirectory stringByAppendingPathComponent:file]]]) {
                continue;
            }*/
            DDLogInfo(@"{\"Ringtone Import\":\"Adding ringtone to be imported: %@\"}", file);
            [m4rFiles addObject:file];
        }
    }
    if ([m4rFiles count] > 0) {
        // Add files to dict
        DDLogInfo(@"{\"Ringtone Import\":\"Found ringtones to import\"}");
        [_ringtonesToImport setObject:m4rFiles forKey:bundleID];
        _shouldImportRingtones = YES;
        
    } else {
        DDLogInfo(@"{\"Ringtone Import\":\"Found 0 ringtones to import\"}");
    }
}

#pragma mark - Should import methods
- (BOOL)shouldImportRingtones {
    DDLogDebug(@"{\"Ringtone Import\":\"shouldImport called with value: %d\"}",_shouldImportRingtones);
    return _shouldImportRingtones;
}

#pragma mark - Import
- (void)importNewRingtones {
    DDLogInfo(@"{\"Ringtone Import\":\"Import called\"}");

    // Loop through files
    NSFileManager *localFileManager = [[NSFileManager alloc] init];
    self.importedCount = 0;
    
    for (NSString *bundleID in _ringtonesToImport) // loop through all bundle ids, one app at a time
    { 
        FBApplicationInfo *appInfo = [LSApplicationProxy applicationProxyForIdentifier:bundleID];
        NSString *oldDirectory = [appInfo.dataContainerURL.path stringByAppendingPathComponent:@"Documents"];
        
        for (NSString *appDirFile in [_ringtonesToImport objectForKey:bundleID]) //loop through nsarray of m4r files
        {
            @autoreleasepool {

                // Create name
                NSString *baseName = [JFTHRingtone createNameFromFile:appDirFile];

                // Create new filename
                NSString *newFile = [[JFTHRingtone randomizedRingtoneParameter:JFTHRingtoneFileName] stringByAppendingString:@".m4r"];

                NSError *fileCopyError;
                if ([localFileManager copyItemAtPath:[
                    oldDirectory stringByAppendingPathComponent:appDirFile]
                                                         toPath:[RINGTONE_DIRECTORY stringByAppendingPathComponent:newFile]
                                                          error:&fileCopyError]) // Will import again at next run if moving. i dont want that.
                {
                    DDLogInfo(@"{\"Ringtone Import\":\"File copy success: %@\"}",appDirFile);
                    //Plist data
                    JFTHRingtone *newTone = [[JFTHRingtone alloc] initWithName:baseName
                                                                      fileName:newFile
                                                                   oldFileName:appDirFile
                                                                      bundleID:bundleID];
                    [_ringtoneDataController addRingtoneToPlist:newTone];
                    
                    self.importedCount++;

                } else {
                    DDLogError(@"{\"Ringtone Import\":\"File copy (%@) failed: %@\"}",appDirFile, fileCopyError);
                }
            }
        }
    }
}

@end
