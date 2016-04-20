//
//  NSString+ValidateEmail.m
//  GymPact
//
//  Created by Bobby Ren on 6/14/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import "NSString+ValidateEmail.h"
#import <Parse/Parse.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Social/Social.h>
#import <Accounts/ACAccount.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "WeTrain-Swift.h"

@implementation NSString (ValidateEmail)
-(BOOL) isValidEmail
{
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}



@end

@implementation Generals

+(CGSize)get_visible_size:(UIViewController*)visibleController {
    CGSize result;
    
    CGSize size = [[UIScreen mainScreen] bounds].size;
    
    result.width = size.width;
    result.height = size.height;
    
    size = [[UIApplication sharedApplication] statusBarFrame].size;
    result.height -= MIN(size.width, size.height);
    
    if (visibleController.navigationController != nil) {
        size = visibleController.navigationController.navigationBar.frame.size;
        result.height -= MIN(size.width, size.height);
    }
    
    if (visibleController.tabBarController != nil) {
        size = visibleController.tabBarController.tabBar.frame.size;
        result.height -= MIN(size.width, size.height);
    }
    
    return result;
}

+ (void)startDownloadVideo
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputURL = paths[0];
    NSFileManager *manager = [NSFileManager defaultManager];
    [manager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
    outputURL = [outputURL stringByAppendingPathComponent:@"motivateMe.mov"];
    
    PFObject *pfObj     = [PFUser currentUser][@"client"];
    PFObject *motivateRequest   = pfObj[@"motivateMe"];
    PFFile *video = motivateRequest[@"video"];
    
//    NSInputStream *stream = [video getDataStream];
//    [stream setDelegate:self];
//    [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//    []
//
//    
//    CFReadStreamRef readStream;
//    inputStream = (__bridge NSInputStream *)readStream;
//    [inputStream setDelegate:self];
//    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoop-Mode];
//    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode: NSDefaultRunLoop-Mode];
//    [inputStream open];
//    [self initNetworkCommunication];
    
    [video getDataStreamInBackgroundWithBlock:^(NSInputStream *stream, NSError *error) {
        if (error == nil) {
            
            [[NSFileManager defaultManager] createFileAtPath:outputURL contents:nil attributes:nil];
            NSFileHandle *hFile = [NSFileHandle fileHandleForWritingAtPath:outputURL];
            if (!hFile) {
                
                //                self.thumb_downloaded = NO;
                //                self.thumb_downerror = YES;
                //                if (self.delegate != nil &&
                //                    [self.delegate respondsToSelector:@selector(thumbnailDownloadFailed:)])
                //                    [self.delegate thumbnailDownloadFailed:self];
                
                return;
            }
            else {
                @try {
                    int read_len;
                    uint8_t buffer[1024];
                    while ((read_len = [stream read:buffer maxLength:1024]) > 0) {
                        NSLog(@"read_len = %d", read_len);
                        NSData *data = [NSData dataWithBytes:buffer length:read_len];
                        [hFile writeData:data];
                    }
                    [hFile closeFile];
                    
                    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            
                    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:[NSURL URLWithString:outputURL]]) {
                        [library writeVideoAtPathToSavedPhotosAlbum:[NSURL URLWithString:outputURL] completionBlock:^(NSURL *assetURL, NSError *error){
                            dispatch_async(dispatch_get_main_queue(), ^{
                                if (error) {
                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Video Saving Failed"
                                                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                    [alert show];
                                } else {
                                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Video Saved" message:@"Saved To Photo Album"
                                                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                    [alert show];
                                }
                            });
                        }];
                    }
                
                    
                    
                    //                    self.thumb_downloaded = YES;
                    //                    self.thumb_downerror = NO;
                    //                    if (self.delegate != nil &&
                    //                        [self.delegate respondsToSelector:@selector(thumbnailDownloaded:)])
                    //                        [self.delegate thumbnailDownloaded:self];
                    return;
                    
                } @catch (NSException *e) {
                    NSLog(@"%@", e.description);
                    [hFile closeFile];
                    
                    //                    self.thumb_downloaded = NO;
                    //                    self.thumb_downerror = YES;
                    //                    if (self.delegate != nil &&
                    //                        [self.delegate respondsToSelector:@selector(thumbnailDownloadFailed:)])
                    //                        [self.delegate thumbnailDownloadFailed:self];
                    return;
                }
            }
        }
        else {
            //            self.thumb_downloaded = NO;
            //            self.thumb_downerror = YES;
            //            if (self.delegate != nil &&
            //                [self.delegate respondsToSelector:@selector(thumbnailDownloadFailed:)])
            //                [self.delegate thumbnailDownloadFailed:self];
            return;
        }
    } progressBlock:^(int percentDone) {
        
        //        if (self.delegate != nil &&
        //            [self.delegate respondsToSelector:@selector(mangaInfo:thumbnailDownloading:)])
        //            [self.delegate mangaInfo:self thumbnailDownloading:percentDone];
    }];
}


+ (void)shareOnTwiiterFromView:(UIViewController *)vc userTitle:(NSString *)title shareURL:(NSString *)urlString
{
    
    
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController
                                               composeViewControllerForServiceType:
                                               SLServiceTypeFacebook];
        
        tweetSheet.completionHandler = ^(SLComposeViewControllerResult result)
        {
            switch(result)
            {
                case SLComposeViewControllerResultCancelled:
                    break;
                case SLComposeViewControllerResultDone:
                    break;
            }
        };
        
        NSString *twTitle = [NSString stringWithFormat:@"%@ %@",title,@"Your App Name"];
        [tweetSheet setInitialText:twTitle];
        
        if (![tweetSheet addURL:[NSURL URLWithString:urlString]])
        {
            NSLog(@"Unable to add the URL!");
        }
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
        {
            UIPresentationController *control = tweetSheet.presentationController;
            [tweetSheet setModalPresentationStyle:UIModalPresentationFormSheet];
            
            [vc presentViewController:control.presentedViewController animated:YES completion:^
             {
                 NSLog(@"Tweet sheet has been presented.");
             }];
        }
        else
        {
            [vc presentViewController:tweetSheet animated:NO completion:^
             {
                 NSLog(@"Tweet sheet has been presented.");
             }];
        }
    }
    else
    {
       // [APP_DEL showErrorAlert:@"No Twitter Account" description:@"There are no twitter accounts configured. You can add or create a Twitter account in Settings."];
    }
}

+(UIImage*)navbarImage{
    
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:200/255.0f green:200/255.0f blue:200/255.0f alpha:1.0] CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    return image;
}

+(UITabBarController *)appRootController {
    
    return (UITabBarController*)[UIApplication sharedApplication].keyWindow.rootViewController.presentedViewController;
}

+(void)ShowLoadingView
{
    if ([AppDelegate isConnectedToNetwork]){
        [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    }
}

+(void)hideLoadingView
{
    if ([AppDelegate isConnectedToNetwork]){
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
    }
}

+(void)showUIinconsistenciesAlert {
    
    NSLog(@"System version %f" , [[[UIDevice currentDevice] systemVersion] floatValue]);
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
        
        //show alert on every launch
        //if ([[NSUserDefaults standardUserDefaults] boolForKey:@"UIinconsistenciesAlert"]  ==  NO || [[NSUserDefaults standardUserDefaults] objectForKey:@"UIinconsistenciesAlert"] == nil)
        {
            
            
            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)); // 1
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message" message:@"WeTrain is optimized to run on the latest IOS version, please excuse any minor formatting inconsistencies if you’re using another version of IOS."
                                                               delegate:self cancelButtonTitle:@"Close" otherButtonTitles:nil];
                alert.tintColor = [UIColor blackColor];
                [alert show];
                
            });
            
            
         
            
            
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"UIinconsistenciesAlert"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
        }
        
    }
    
}

@end




@implementation SocialVideoHelper

#define DispatchMainThread(block, ...) if(block) dispatch_async(dispatch_get_main_queue(), ^{ block(__VA_ARGS__); })

#define Video_Chunk_Max_size 1000 * 1000 * 5

+(void)uploadError:(NSError*)error withCompletion:(VideoUploadCompletion)completion{
    NSString *errorDes = [error localizedDescription];
    NSLog(@"There was an error:%@", errorDes);
    DispatchMainThread(^(){completion(NO, errorDes);});
}

+(void)uploadSuccessWithCompletion:(VideoUploadCompletion)completion{
    DispatchMainThread(^(){completion(YES, nil);});
}

#pragma mark - For Facebook

+(BOOL)userHasAccessToFacebook
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook];
}

+(void)uploadFacebookVideo:(NSData*)videoData comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    
    NSURL *facebookPostURL = [[NSURL alloc] initWithString:@"https://graph-video.facebook.com/v2.3/me/videos"];
    
    NSDictionary *postParams = @{
                                 @"access_token": account.credential.oauthToken,
                                 @"upload_phase" : @"start",
                                 @"file_size" : [NSNumber numberWithInteger: videoData.length].stringValue
                                 };
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:facebookPostURL parameters:postParams];
    request.account = account;
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Facebook Stage1 HTTP Response: %li, responseData: %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"Facebook Error stage 1 - %@", error);
            [SocialVideoHelper uploadError:error withCompletion:completion];
        } else {
            NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            
            NSLog(@"Facebook Stage1 dic -> %@", returnedData);
            
            NSString *upload_session_id = returnedData[@"upload_session_id"];
            [SocialVideoHelper facebookVideoStage2:videoData comment:(NSString*)comment upload_session_id:upload_session_id account:account withCompletion:completion];
        }
    }];
    
}

+(void)facebookVideoStage2:(NSData*)videoData comment:(NSString*)comment upload_session_id:(NSString *)upload_session_id account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    
    NSURL *facebookPostURL = [[NSURL alloc] initWithString:@"https://graph-video.facebook.com/v2.3/me/videos"];
    
    NSDictionary *postParams = @{
                                 @"access_token": account.credential.oauthToken,
                                 @"upload_phase" : @"transfer",
                                 @"start_offset" : @"0",
                                 @"upload_session_id" : upload_session_id
                                 };
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:facebookPostURL parameters:postParams];
    request.account = account;
    
    [request addMultipartData:videoData withName:@"video_file_chunk" type:@"video/mov" filename:@"video"];
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Facebook Stage2 HTTP Response: %li, responseData: %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"Facebook Error stage 2 - %@", error);
            [SocialVideoHelper uploadError:error withCompletion:completion];
        } else {
            NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            
            NSLog(@"Facebook Stage2 dic -> %@", returnedData);
            
            [SocialVideoHelper facebookVideoStage3:videoData comment:(NSString*)comment upload_session_id:upload_session_id account:account withCompletion:completion];
        }
    }];
}


+(void)facebookVideoStage3:(NSData*)videoData comment:(NSString*)comment upload_session_id:(NSString *)upload_session_id account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    
    NSURL *facebookPostURL = [[NSURL alloc] initWithString:@"https://graph-video.facebook.com/v2.3/me/videos"];
    
    if (comment == nil) {
        comment = [NSString stringWithFormat:@"#SocialVideoHelper# https://github.com/liu044100/SocialVideoHelper"];
    }
    
    NSDictionary *postParams = @{
                                 @"access_token": account.credential.oauthToken,
                                 @"upload_phase" : @"finish",
                                 @"upload_session_id" : upload_session_id,
                                 @"description": comment
                                 };
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeFacebook requestMethod:SLRequestMethodPOST URL:facebookPostURL parameters:postParams];
    request.account = account;
    
    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Facebook Stage3 HTTP Response: %li, responseData: %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"Facebook Error stage 3 - %@", error);
            [SocialVideoHelper uploadError:error withCompletion:completion];
        } else {
            NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
            NSLog(@"Facebook Stage3 dic -> %@", returnedData);
            
            if ([urlResponse statusCode] == 200){
                NSLog(@"Facebook upload success !");
                [SocialVideoHelper uploadSuccessWithCompletion:completion];
            }
        }
    }];
}

#pragma mark - For Twitter

+(BOOL)userHasAccessToTwitter
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

+(void)uploadTwitterVideo:(NSData*)videoData comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    
    
    {
        ACAccountStore *account = [[ACAccountStore alloc] init];
        ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:
                                      ACAccountTypeIdentifierTwitter];
        
        [account requestAccessToAccountsWithType:accountType options:nil
                                      completion:^(BOOL granted, NSError *error)
         {
             if (granted == YES)
             {
                 // Get account and communicate with Twitter API
                 NSArray *arrayOfAccounts = [account
                                             accountsWithAccountType:accountType];
                 
                 if ([arrayOfAccounts count] > 0)
                 {
                     ACAccount *twitterAccount = [arrayOfAccounts lastObject];
                     
                     
                     
                     NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
                     
                     NSDictionary *postParams = @{@"command": @"INIT",
                                                  @"total_bytes" : [NSNumber numberWithInteger: videoData.length].stringValue,
                                                  @"media_type" : @"video/mov"
                                                  };
                     
                     SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
                     request.account = twitterAccount;
                     [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                         NSLog(@"Twitter Stage1 HTTP Response: %li, responseData: %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                         if (error) {
                             NSLog(@"Twitter Error stage 1 - %@", error);
                             [SocialVideoHelper uploadError:error withCompletion:completion];
                         } else {
                             NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
                             
                             NSString *mediaID = [NSString stringWithFormat:@"%@", [returnedData valueForKey:@"media_id_string"]];
                             
                             [SocialVideoHelper tweetVideoStage2:videoData mediaID:mediaID comment:comment account:twitterAccount withCompletion:completion];
                             
                             NSLog(@"stage one success, mediaID -> %@", mediaID);
                         }
                     }];
                 }
             }
             else
             {
                 NSLog(@"No Twitter Access Error");
                 return;
             }
         }];
    }
    
    
    
   
    
   
}

+(void)tweetVideoStage2:(NSData*)videoData mediaID:(NSString *)mediaID comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    
    NSArray *chunks = [SocialVideoHelper separateToMultipartData:videoData];
    NSMutableArray *requests = [NSMutableArray array];
    
    for (int i = 0; i < chunks.count; i++) {
        NSString *seg_index = [NSString stringWithFormat:@"%d",i];
        NSDictionary *postParams = @{@"command": @"APPEND",
                                     @"media_id" : mediaID,
                                     @"segment_index" : seg_index,
                                     };
        SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
        postRequest.account = account;
        [postRequest addMultipartData:chunks[i] withName:@"media" type:@"video/mov" filename:@"video"];
        [requests addObject:postRequest];
    }
    
    __block NSError *theError = nil;
    dispatch_queue_t chunksRequestQueue = dispatch_queue_create("chunksRequestQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(chunksRequestQueue, ^{
        dispatch_group_t requestGroup = dispatch_group_create();
        for (int i = 0; i < (requests.count - 1); i++) {
            dispatch_group_enter(requestGroup);
            SLRequest *postRequest = requests[i];
            [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                NSLog(@"Twitter Stage2 - %d HTTP Response: %li, %@", (i+1),(long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                if (error) {
                    NSLog(@"Twitter Error stage 2 - %d, error - %@", (i+1), error);
                    theError = error;
                } else {
                    if (i == requests.count - 1) {
                        [SocialVideoHelper tweetVideoStage3:videoData mediaID:mediaID comment:comment account:account withCompletion:completion];
                    }
                }
                dispatch_group_leave(requestGroup);
            }];
            dispatch_group_wait(requestGroup, DISPATCH_TIME_FOREVER);
        }
        
        if (theError) {
            [SocialVideoHelper uploadError:theError withCompletion:completion];
        } else {
            SLRequest *postRequest = requests.lastObject;
            [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                NSLog(@"Twitter Stage2 - final, HTTP Response: %li, %@",(long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                if (error) {
                    NSLog(@"Twitter Error stage 2 - final, error - %@", error);
                } else {
                    [SocialVideoHelper tweetVideoStage3:videoData mediaID:mediaID comment:comment account:account withCompletion:completion];
                }
            }];
        }
    });
}

+(void)tweetVideoStage3:(NSData*)videoData mediaID:(NSString *)mediaID comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    
    NSDictionary *postParams = @{@"command": @"FINALIZE",
                                 @"media_id" : mediaID };
    
    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
    
    // Set the account and begin the request.
    postRequest.account = account;
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Twitter Stage3 HTTP Response: %li, %@", (long)[urlResponse statusCode], [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        if (error) {
            NSLog(@"Twitter Error stage 3 - %@", error);
            [SocialVideoHelper uploadError:error withCompletion:completion];
        } else {
            [SocialVideoHelper tweetVideoStage4:videoData mediaID:mediaID comment:comment account:account withCompletion:completion];
        }
    }];
}

+(void)tweetVideoStage4:(NSData*)videoData mediaID:(NSString *)mediaID comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion{
    NSURL *twitterPostURL = [[NSURL alloc] initWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    
    if (comment == nil) {
        comment = [NSString stringWithFormat:@"#SocialVideoHelper# https://github.com/liu044100/SocialVideoHelper"];
    }
    
    // Set the parameters for the third twitter video request.
    NSDictionary *postParams = @{@"status": comment,
                                 @"media_ids" : @[mediaID]};
    
    SLRequest *postRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:twitterPostURL parameters:postParams];
    postRequest.account = account;
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSLog(@"Twitter Stage4 HTTP Response: %li", (long)[urlResponse statusCode]);
        if (error) {
            NSLog(@"Twitter Error stage 4 - %@", error);
            [SocialVideoHelper uploadError:error withCompletion:completion];
        } else {
            if ([urlResponse statusCode] == 200){
                NSLog(@"Twitter upload success !");
                [SocialVideoHelper uploadSuccessWithCompletion:completion];
            }
        }
    }];
}

+(NSArray*)separateToMultipartData:(NSData*)videoData{
    NSMutableArray *multipartData = [NSMutableArray new];
    CGFloat length = videoData.length;
    CGFloat standard_length = Video_Chunk_Max_size;
    if (length <= standard_length) {
        [multipartData addObject:videoData];
        NSLog(@"need not separate as chunk, data size -> %ld bytes", (long)videoData.length);
    } else {
        NSUInteger count = ceil(length/standard_length);
        for (int i = 0; i < count; i++) {
            NSRange range;
            if (i == count - 1) {
                range = NSMakeRange(i * standard_length, length - i * standard_length);
            } else {
                range = NSMakeRange(i * standard_length, standard_length);
            }
            NSData *part_data = [videoData subdataWithRange:range];
            [multipartData addObject:part_data];
            NSLog(@"chunk index -> %d, data size -> %ld bytes", (i+1), (long)part_data.length);
        }
    }
    return multipartData.copy;
}

@end