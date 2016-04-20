//
//  NSString+ValidateEmail.h
//  GymPact
//
//  Created by Bobby Ren on 6/14/13.
//  Copyright (c) 2013 Harvard University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface NSString (ValidateEmail)

-(BOOL) isValidEmail;



@end


@interface Generals : NSObject

+ (void)startDownloadVideo;
+ (void)shareOnTwiiterFromView:(UIViewController *)vc userTitle:(NSString *)title shareURL:(NSString *)urlString;
+ (CGSize)get_visible_size:(UIViewController*)visibleController;
+ (UIImage*)navbarImage;
+(UITabBarController *)appRootController;

+(void)ShowLoadingView;
+(void)hideLoadingView;
+(void)showUIinconsistenciesAlert;
@end


#import <Foundation/Foundation.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

typedef void(^VideoUploadCompletion)(BOOL success, NSString *errorMessage);

@interface SocialVideoHelper : NSObject

+(void)uploadTwitterVideo:(NSData*)videoData comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion;
+(void)uploadFacebookVideo:(NSData*)videoData comment:(NSString*)comment account:(ACAccount*)account withCompletion:(VideoUploadCompletion)completion;
+(BOOL)userHasAccessToFacebook;
+(BOOL)userHasAccessToTwitter;

@end