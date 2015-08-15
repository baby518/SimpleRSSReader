//
//  BaseFMDBUtil.h
//  
//
//  Created by zhangchao on 15/7/28.
//
//

#import <Foundation/Foundation.h>
#import "RSSChannelElement.h"

@class FMDatabase;

/** a wrapper of FMDB */
@interface BaseFMDBUtil : NSObject {
@protected
    FMDatabase *dataBase;
    BOOL databaseIsReady;
}

// open it
- (instancetype)initWithDBPath:(NSString *)path;

//close
- (void)closeDB;

/** need override by child. */
- (NSString *)getFeedTableName;

- (BOOL)isTableExist:(NSString *)tableName;

// query
- (NSArray *)getAllFeedChannels;
- (NSArray *)getStarredChannels;
- (NSArray *)getAllCategories;
- (NSArray *)getChannelsInCategory:(NSString *)category;
- (RSSChannelElement *)getChannelFromURL:(NSString *)url;

// other util functions
- (NSString *)encodeBase64:(NSData *)imageData;
- (NSData *)decodeBase64:(NSString *)base64String;

- (NSInteger)encodeDate:(NSDate *)date;
- (NSDate *)decodeDate:(NSInteger)dateValue;
@end