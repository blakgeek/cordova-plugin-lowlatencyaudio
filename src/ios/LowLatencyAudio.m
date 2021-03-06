//
//  LowLatencyAudio.m
//  LowLatencyAudio
//
//  Created by Andrew Trice on 1/19/12.
//
// THIS SOFTWARE IS PROVIDED BY ANDREW TRICE "AS IS" AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
// EVENT SHALL ANDREW TRICE OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "LowLatencyAudio.h"

@implementation LowLatencyAudio

NSString *ERROR_NOT_FOUND = @"file not found";
NSString *WARN_EXISTING_REFERENCE = @"a reference to the audio ID already exists";
NSString *ERROR_MISSING_REFERENCE = @"a reference to the audio ID does not exist";
NSString *CONTENT_LOAD_REQUESTED = @"content has been requested";
NSString *PLAY_REQUESTED = @"PLAY REQUESTED";
NSString *STOP_REQUESTED = @"STOP REQUESTED";
NSString *UNLOAD_REQUESTED = @"UNLOAD REQUESTED";
NSString *RESTRICTED = @"ACTION RESTRICTED FOR FX AUDIO";
NSString *PRELOAD_FX_MSG = @"Preloading FX - %@";
NSString *PRELOAD_AUDIO_MSG = @"Preloading Audio - %@";

- (void)pluginInitialize {
    // make sure audio doesn't take over should probably add a flag to control this
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)preloadFX:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    NSArray *arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    NSString *assetPath = [arguments objectAtIndex:1];

    NSLog(PRELOAD_FX_MSG, assetPath);

    if (audioMapping == nil) {
        audioMapping = [NSMutableDictionary dictionary];
    }

    [self.commandDelegate runInBackground:^{

        CDVPluginResult *pluginResult;
        NSNumber *existingReference = [audioMapping objectForKey:audioID];
        if (existingReference == nil) {
            NSString *basePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"www"];
            NSString *path = [NSString stringWithFormat:@"%@", assetPath];
            NSString *pathFromWWW = [NSString stringWithFormat:@"%@/%@", basePath, assetPath];


            if(logging
            NSLog(@"basePath: %@", basePath);
            NSLog(@"path: %@", path);
            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                NSURL *pathURL = [NSURL fileURLWithPath:path];
                CFURLRef soundFileURLRef = (CFURLRef) CFBridgingRetain(pathURL);
                SystemSoundID soundID;
                AudioServicesCreateSystemSoundID(soundFileURLRef, &soundID);
                [audioMapping setObject:[NSNumber numberWithInt:soundID] forKey:audioID];

                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:CONTENT_LOAD_REQUESTED];
            } else if ([[NSFileManager defaultManager] fileExistsAtPath:pathFromWWW]) {
                NSURL *pathURL = [NSURL fileURLWithPath:pathFromWWW];
                CFURLRef soundFileURLRef = (CFURLRef) CFBridgingRetain(pathURL);
                SystemSoundID soundID;
                AudioServicesCreateSystemSoundID(soundFileURLRef, &soundID);
                [audioMapping setObject:[NSNumber numberWithInt:soundID] forKey:audioID];

                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:CONTENT_LOAD_REQUESTED];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:ERROR_NOT_FOUND];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:WARN_EXISTING_REFERENCE];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)preloadAudio:(CDVInvokedUrlCommand *)command {

    NSString *callbackId = command.callbackId;
    NSArray *arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    NSString *assetPath = [arguments objectAtIndex:1];

    NSLog(PRELOAD_AUDIO_MSG, assetPath);

    NSNumber *volume = nil;
    if ([arguments count] > 2) {
        volume = [arguments objectAtIndex:2];
        if ([volume isEqual:nil]) {
            volume = [NSNumber numberWithFloat:1.0f];
        }
    } else {
        volume = [NSNumber numberWithFloat:1.0f];
    }

    NSLog(@"volume - %@", volume.stringValue);

    NSNumber *voices = nil;
    if ([arguments count] > 3) {
        voices = [arguments objectAtIndex:3];
        if ([voices isEqual:nil]) {
            voices = [NSNumber numberWithInt:1];
        }
    } else {
        voices = [NSNumber numberWithInt:1];
    }

    if (audioMapping == nil) {
        audioMapping = [NSMutableDictionary dictionary];
    }

    NSNumber *existingReference = [audioMapping objectForKey:audioID];

    [self.commandDelegate runInBackground:^{
        if (existingReference == nil) {
            NSString *basePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"www"];
            NSString *path = [NSString stringWithFormat:@"%@/%@", basePath, assetPath];

            if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
                LowLatencyAudioAsset *asset = [[LowLatencyAudioAsset alloc] initWithPath:path withVoices:voices withVolume:volume];
                [audioMapping setObject:asset forKey:audioID];
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:CONTENT_LOAD_REQUESTED] callbackId:callbackId];
                NSLog(@"audio file %@ loaded", path);
            } else {
                NSLog(@"audio file not found");
                [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:ERROR_NOT_FOUND] callbackId:callbackId];
            }
        } else {
            NSLog(@"audioID %@ is already mapped", audioID);
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:WARN_EXISTING_REFERENCE] callbackId:callbackId];
        }

    }];
}

- (void)fadeIn:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    NSString *audioID = [command argumentAtIndex:0];
    NSNumber *duration = [command argumentAtIndex:1 withDefault:[NSNumber numberWithFloat:1.0f]];

    //NSLog( @"play - %@", audioID );
    [self.commandDelegate runInBackground:^{
        if (audioMapping) {
            NSObject *asset = [audioMapping objectForKey:audioID];
            if ([asset isKindOfClass:[LowLatencyAudioAsset class]]) {
                LowLatencyAudioAsset *_asset = (LowLatencyAudioAsset *) asset;
                [_asset fadeIn:duration];
            } else if ([asset isKindOfClass:[NSNumber class]]) {
                NSNumber *_asset = (NSNumber *) asset;
                AudioServicesPlaySystemSound([_asset intValue]);
            }

            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:PLAY_REQUESTED] callbackId:callbackId];
        } else {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:ERROR_MISSING_REFERENCE] callbackId:callbackId];
        }
    }];

}

- (void)play:(CDVInvokedUrlCommand *)command {

    NSString *callbackId = command.callbackId;
    NSString *audioID = [command argumentAtIndex:0];


    //NSLog( @"play - %@", audioID );
    [self.commandDelegate runInBackground:^{
        if (audioMapping) {
            NSObject *asset = [audioMapping objectForKey:audioID];
            if ([asset isKindOfClass:[LowLatencyAudioAsset class]]) {
                LowLatencyAudioAsset *_asset = (LowLatencyAudioAsset *) asset;
                [_asset play];

            } else if ([asset isKindOfClass:[NSNumber class]]) {
                NSNumber *_asset = (NSNumber *) asset;
                AudioServicesPlaySystemSound([_asset intValue]);
            }

            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:PLAY_REQUESTED] callbackId:callbackId];
        } else {
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:ERROR_MISSING_REFERENCE] callbackId:callbackId];
        }
    }];
}

- (void)stop:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    NSArray *arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];

    //NSLog( @"stop - %@", audioID );

    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;

        if (audioMapping) {
            NSObject *asset = [audioMapping objectForKey:audioID];
            if ([asset isKindOfClass:[LowLatencyAudioAsset class]]) {
                LowLatencyAudioAsset *_asset = (LowLatencyAudioAsset *) asset;
                [_asset stop];

                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:STOP_REQUESTED];
            } else if ([asset isKindOfClass:[NSNumber class]]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:RESTRICTED];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:ERROR_MISSING_REFERENCE];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)fadeOut:(CDVInvokedUrlCommand *)command {
    NSString *callbackId = command.callbackId;
    NSArray *arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];

    //NSLog( @"stop - %@", audioID );

    [self.commandDelegate runInBackground:^{
        CDVPluginResult *pluginResult;

        if (audioMapping) {
            NSObject *asset = [audioMapping objectForKey:audioID];
            if ([asset isKindOfClass:[LowLatencyAudioAsset class]]) {
                LowLatencyAudioAsset *_asset = (LowLatencyAudioAsset *) asset;
                [_asset stop];

                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:STOP_REQUESTED];
            } else if ([asset isKindOfClass:[NSNumber class]]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:RESTRICTED];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:ERROR_MISSING_REFERENCE];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)loop:(CDVInvokedUrlCommand *)command {

    NSString *callbackId = command.callbackId;
    NSString *audioID = [command argumentAtIndex:0];

    NSLog(@"loop - %@", audioID);

    [self.commandDelegate runInBackground:^{

        CDVPluginResult *pluginResult;
        if (audioMapping) {
            NSObject *asset = [audioMapping objectForKey:audioID];
            if ([asset isKindOfClass:[LowLatencyAudioAsset class]]) {
                LowLatencyAudioAsset *_asset = (LowLatencyAudioAsset *) asset;
                [_asset loop];

                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:STOP_REQUESTED];
            } else if ([asset isKindOfClass:[NSNumber class]]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:RESTRICTED];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:ERROR_MISSING_REFERENCE];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)fadeInLoop:(CDVInvokedUrlCommand *)command {

    NSString *callbackId = command.callbackId;
    NSString *audioID = [command argumentAtIndex:0];
    NSNumber *duration = [command argumentAtIndex:1 withDefault:[NSNumber numberWithFloat:1.0f]];

    NSLog(@"loop - %@", audioID);

    [self.commandDelegate runInBackground:^{

        CDVPluginResult *pluginResult;
        if (audioMapping) {

            NSObject *asset = [audioMapping objectForKey:audioID];
            if ([asset isKindOfClass:[LowLatencyAudioAsset class]]) {
                LowLatencyAudioAsset *_asset = (LowLatencyAudioAsset *) asset;
                [_asset fadeInLoop: duration];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:STOP_REQUESTED];
            } else if ([asset isKindOfClass:[NSNumber class]]) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:RESTRICTED];
            }
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:ERROR_MISSING_REFERENCE];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

- (void)setVolume:(CDVInvokedUrlCommand *)command {

    NSString *callbackId = command.callbackId;
    NSArray *arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];
    NSNumber *volume = [command argumentAtIndex:1];

    NSLog(@"unload - %@", audioID);

    [self.commandDelegate runInBackground:^{

        CDVPluginResult *pluginResult;
        if (audioMapping) {
            NSObject *asset = [audioMapping objectForKey:audioID];
            if ([asset isKindOfClass:[LowLatencyAudioAsset class]]) {
                LowLatencyAudioAsset *_asset = (LowLatencyAudioAsset *) asset;
                [_asset setVolume:volume];
            } else if ([asset isKindOfClass:[NSNumber class]]) {
                NSNumber *_asset = (NSNumber *) asset;
                AudioServicesDisposeSystemSoundID([_asset intValue]);
            }

            [audioMapping removeObjectForKey:audioID];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:UNLOAD_REQUESTED];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:ERROR_MISSING_REFERENCE];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}
- (void)unload:(CDVInvokedUrlCommand *)command {

    NSString *callbackId = command.callbackId;
    NSArray *arguments = command.arguments;
    NSString *audioID = [arguments objectAtIndex:0];

    NSLog(@"unload - %@", audioID);

    [self.commandDelegate runInBackground:^{

        CDVPluginResult *pluginResult;
        if (audioMapping) {
            NSObject *asset = [audioMapping objectForKey:audioID];
            if ([asset isKindOfClass:[LowLatencyAudioAsset class]]) {
                LowLatencyAudioAsset *_asset = (LowLatencyAudioAsset *) asset;
                [_asset unload];
            } else if ([asset isKindOfClass:[NSNumber class]]) {
                NSNumber *_asset = (NSNumber *) asset;
                AudioServicesDisposeSystemSoundID([_asset intValue]);
            }

            [audioMapping removeObjectForKey:audioID];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:UNLOAD_REQUESTED];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:ERROR_MISSING_REFERENCE];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    }];
}

@end
