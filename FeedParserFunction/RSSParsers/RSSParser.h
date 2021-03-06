//
//  RSSParser.h
//  RSSReader
//
//  Created by zhangchao on 15/4/4.
//  Copyright (c) 2015年 zhangchao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSSSchema.h"
#import "RSSChannelElement.h"
#import "RSSItemElement.h"
#import "LogHelper.h"

typedef NS_ENUM(NSInteger, XMLElementStringStyle) {
    /** return all result ues NSString*/
    XMLElementStringNormal           = 0,
    /** return result filtered HTML label.*/
    XMLElementStringFilterHtmlLabel  = 1,
};
#define XMLElementStringStyleArrays @[@"Normal", @"FilterHtmlLabel"]

typedef NS_ENUM(NSInteger, FeedType) {
    FeedTypeUnknown = 0,
    FeedTypeRSS     = 1,
    FeedTypeAtom    = 2,
};

@protocol RSSParserDelegate <NSObject>
- (void)parseErrorOccurred:(NSError *)error;
- (void)elementDidParsed:(RSSBaseElement *)element;
- (void)allElementsDidParsed;
@end

@interface RSSParser : NSObject {
@protected
    XMLElementStringStyle xmlElementStringStyle;
    FeedType feedType;
    BOOL parsing;
}

@property (nonatomic, weak) id <RSSParserDelegate> delegate;
@property (nonatomic, strong, readonly) NSData* xmlData;
@property (nonatomic, strong, readonly) NSArray* filterKeyArray;
- (id)initWithData:(NSData *)data;
- (void)startParser;
- (void)startParserWithStyle:(XMLElementStringStyle)elementStringStyle;
- (void)stopParser;
- (BOOL)isParsing;
- (void)didParserFinish;

- (void)setFilterArray:(NSArray *)array;
- (BOOL)needIgnoreItem:(NSString *)string;
// try to set protected later
- (void)postErrorOccurred:(NSError *)error;
// try to set protected later
- (void)postElementDidParsed:(RSSBaseElement *)element;
// try to set protected later
- (void)postAllElementsDidParsed;
@end
