//
//  AppDelegate.m
//  M2MReceiver
//
//  Created by 石田 勝嗣 on 2014/10/19.
//  Copyright (c) 2014年 石田 勝嗣. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()
@property CLBeaconRegion *beaconRegion;
@property CLLocationManager *manager;
@property NSArray *plist;
@property NSMutableArray *names;

@property BOOL notified;

@end

static NSString *const UUID = @"7B5FA67D-5B28-422A-A028-9C537ACCDE0B";
static NSString *const identifier = @"m2m.beacon";

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // read appliance plist
    NSString* path = [[NSBundle mainBundle] pathForResource:@"ApplianceList" ofType:@"plist"];
    self.plist = [NSArray arrayWithContentsOfFile:path];
    
    NSInteger count = [self.plist count];
    
    self.names = [[NSMutableArray alloc] initWithCapacity:count];

    NSEnumerator *enumerator =[self.plist objectEnumerator];
    id obj;
    while(obj =[enumerator nextObject]){
        NSDictionary *dict = (NSDictionary*)obj;
        NSString *name = [dict objectForKey:(@"name")];
        [self.names addObject:name];
    }
    NSLog(@"%@", self.names);
    
    // Construct the region
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUID] identifier:identifier];
    //self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[[NSUUID alloc] initWithUUIDString:UUID] major:1 minor:1 identifier:identifier];
    self.beaconRegion.notifyEntryStateOnDisplay = YES ;
    self.beaconRegion.notifyOnExit = YES;
    
    // Start monitoring
    self.manager = [[CLLocationManager alloc] init];
    [self.manager setDelegate:self];
    
    // Register notification setting
    UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    
    self.notified = false;
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            NSLog(@"Got authorization, start monitoring location");
            [self startMonitor];
            break;
        case kCLAuthorizationStatusNotDetermined:
            [self.manager requestAlwaysAuthorization];
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    [self.manager requestStateForRegion:region];
    NSLog(@"Requested state for Beacon Region %@", region);
}

-(void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region
{
    NSString *str;
    switch (state) {
        case CLRegionStateInside:
            if([region isMemberOfClass:[CLBeaconRegion class]]){
                
                [manager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
            }
            str = @"inside";
            break;
            
        case CLRegionStateOutside:
            str = @"outside";
            self.notified = false;
            break;
        case CLRegionStateUnknown:
            str = @"unknown";
            self.notified = false;
            break;
            
        default:
            break;
    }
    NSLog(@"State of the region: state %@ region %@",str, region);
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Failed With Error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"Did Enter Region %@", region);
    if ([region isKindOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [manager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
        NSLog(@"start Ranging");
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"Did Exit Region %@", region);
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        [manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
        self.notified = false;
        NSLog(@"stop Ranging");
    }
}

- (void)locationManager:(CLLocationManager *)manager
rangingBeaconsDidFailForRegion:(CLBeaconRegion *)region
              withError:(NSError *)error {
    NSLog(@"Ranging beacon failed With Error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region
{
    for (CLBeacon *beacon in beacons) {
        NSLog(@"Did range Beacons %@", beacon);
        UILocalNotification *notification = [UILocalNotification new];
        notification.soundName = UILocalNotificationDefaultSoundName;
        
        NSNumber *major = beacon.major;
        NSInteger index = [major integerValue];
        NSString *alert = [NSString stringWithFormat:(@"%@からの通知です。"), [self.names objectAtIndex:(index)]];
        notification.alertBody = alert;
        
        ViewController *topViewController = (ViewController *)[self.window rootViewController];
        [topViewController.appName setText:[self.names objectAtIndex:(index)]];
        [topViewController.messge setText:[self getMsg:self.plist major:[beacon.major integerValue] minor:[beacon.minor integerValue]]];
        
        if (self.notified == false) {
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
            self.notified = true;
        }
    }
    //[manager stopRangingBeaconsInRegion:(CLBeaconRegion *)region];
}

- (void)startMonitor {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        [self.manager requestAlwaysAuthorization];
    }
    [self.manager startMonitoringForRegion:self.beaconRegion];
}

-(NSString*)getMsg:(NSArray *)plist major:(NSInteger)major minor:(NSInteger)minor {
    NSDictionary *dict = (NSDictionary*)[plist objectAtIndex:(major)];
    NSArray *array = [dict objectForKey:@"msgs"];
    return [array objectAtIndex:minor];
}
@end
