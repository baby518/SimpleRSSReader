//
// Created by zhangchao on 14/10/26.
// Copyright (c) 2014 zhangchao. All rights reserved.
//

#import "RSSSchema.h"

NSString *const ROOT_NAME                           = @"rss";
NSString *const ROOT_NAME_PATH                      = @"/rss";
NSString *const ATTRIBUTE_ROOT_VERSION              = @"version";

NSString *const ELEMENT_CHANNEL                     = @"channel";
NSString *const ELEMENT_CHANNEL_PATH                = @"/rss/channel";
NSString *const ELEMENT_CHANNEL_TITLE               = @"title";
NSString *const ELEMENT_CHANNEL_TITLE_PATH          = @"/rss/channel/title";
NSString *const ELEMENT_CHANNEL_LINK                = @"link";
NSString *const ELEMENT_CHANNEL_LINK_PATH           = @"/rss/channel/link";
NSString *const ELEMENT_CHANNEL_DESCRIPTION         = @"description";
NSString *const ELEMENT_CHANNEL_DESCRIPTION_PATH    = @"/rss/channel/description";
NSString *const ELEMENT_CHANNEL_PUBDATE             = @"pubDate";
NSString *const ELEMENT_CHANNEL_PUBDATE_PATH        = @"/rss/channel/pubDate";
NSString *const ELEMENT_CHANNEL_LANGUAGE            = @"language";
NSString *const ELEMENT_CHANNEL_LANGUAGE_PATH       = @"/rss/channel/language";
NSString *const ELEMENT_CHANNEL_COPYRIGHT           = @"copyright";
NSString *const ELEMENT_CHANNEL_COPYRIGHT_PATH      = @"/rss/channel/copyright";

NSString *const ELEMENT_ITEM                    = @"item";
NSString *const ELEMENT_ITEM_PATH               = @"/rss/channel/item";
NSString *const ELEMENT_ITEM_TITLE              = @"title";
NSString *const ELEMENT_ITEM_TITLE_PATH         = @"/rss/channel/item/title";
NSString *const ELEMENT_ITEM_LINK               = @"link";
NSString *const ELEMENT_ITEM_LINK_PATH          = @"/rss/channel/item/link";
NSString *const ELEMENT_ITEM_DESCRIPTION        = @"description";
NSString *const ELEMENT_ITEM_DESCRIPTION_PATH   = @"/rss/channel/item/description";
NSString *const ELEMENT_ITEM_PUBDATE            = @"pubDate";
NSString *const ELEMENT_ITEM_PUBDATE_PATH       = @"/rss/channel/item/pubDate";
NSString *const ELEMENT_ITEM_DC_CREATOR         = @"dc:creator";
NSString *const ELEMENT_ITEM_DC_CREATOR_PATH    = @"/rss/channel/item/dc:creator";
NSString *const ELEMENT_ITEM_AUTHOR             = @"author";
NSString *const ELEMENT_ITEM_AUTHOR_PATH        = @"/rss/channel/item/author";
NSString *const ELEMENT_ITEM_GUID               = @"guid";
NSString *const ELEMENT_ITEM_GUID_PATH          = @"/rss/channel/item/guid";

int const MAX_ELEMENT_COUNTS                    = 100;

@implementation RSSSchema
+ (NSDate *)convertString2Date:(NSString *)string {
    if (string == nil) return nil;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    //Tue, 03 Feb 2015 15:57:37 GMT
    //Thu, 05 Feb 2015 09:00:00 -0500
    //@"EEE, dd MMM yyyy HH:mm:ss Z"
    [dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];

    NSDate *result = [dateFormatter dateFromString:string];
    return result;
}

+ (NSString *)convertDate2String:(NSDate *)time {
    if (time == nil) return @"null";
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];

    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale currentLocale] localeIdentifier]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:time];
    return dateString;
}
@end