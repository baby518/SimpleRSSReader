//
//  XMLParser.m
//  RSSReader
//
//  Created by zhangchao on 15/2/5.
//  Copyright (c) 2015年 zhangchao. All rights reserved.
//

#import "FeedParser.h"
#import "NSRSSParser.h"
#import "GDataRSSParser.h"
#import "AtomSchema.h"
#import "HTMLSchema.h"
#import "TFHpple.h"
#import "PresetFMDBUtil.h"
#import "UserFMDBUtil.h"

#pragma mark FeedParser (private)
@interface FeedParser ()
@property(nonatomic, strong, readonly) NSURL *feedURL;
@property(nonatomic, strong) NSURLSession *URLSession;
@property(nonatomic, strong) NSURLSessionDataTask *URLSessionDataTask;

@property(nonatomic, assign, readonly) BOOL needHTMLParse;

@property(nonatomic, strong) PresetFMDBUtil *presetDB;
- (void)initializeData:(NSData *)data;
@end

#pragma mark FeedParser
@implementation FeedParser

- (id)init {
    self = [super self];
    if (self) {
        _blackList = [NSMutableArray array];
        _needHTMLParse = YES;
    }
    return self;
}

- (id)initWithData:(NSData *)data {
    self = [self init];
    if (self) {
        [self initializeData:data];
    }
    return self;
}

- (id)initWithURL:(NSURL *)feedURL {
    self = [self init];
    if (self) {
        _feedURL = feedURL;
    }
    return self;
}

- (NSURLSession *)URLSession {
    if (_URLSession == nil) {
        _URLSession = [NSURLSession sharedSession];
    }
    return _URLSession;
}

- (void)startRequestSync:(NSError **)errorPtr {
    NSError *urlError = nil;
    // Method 1 : use NSData load URL
    NSData *urlData = [NSData dataWithContentsOfURL:self.feedURL options:NSDataReadingMappedIfSafe error:&urlError];
    if (urlData && !urlError) {
        [self initializeData:urlData];
    } else {
        LOGE(@"initWithURL loadDataFromURL error is %@", urlError);
        if (urlError && errorPtr) {
            *errorPtr = [[NSError alloc] initWithDomain:urlError.domain code:urlError.code userInfo:urlError.userInfo];
        }
    }

//    // Method 2 : use NSURLConnection sync request
//    // Create default request with no caching
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.feedURL
//                                                                cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
//                                                            timeoutInterval:60];
//    // Sync
//    NSURLResponse *response = nil;
//    NSError *error = nil;
//    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
//    if (data && !error) {
//        [self initializeData:data];
//    } else {
//        LOGE(@"loadDataFromURL error is %@", error);
//        if (error && errorPtr) {
//            *errorPtr = [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:error.userInfo];
//        }
//    }
}

- (void)startRequestAsync:(void (^)(NSError *error))handler {
    _needHTMLParse = true;
    [self goOnRequestAsync:handler];
}

- (void)goOnRequestAsync:(void (^)(NSError *error))handler {
    // Method 3: use NSURLConnection Async copy from SeismicXML
    NSURLRequest *feedURLRequest = [NSURLRequest requestWithURL:self.feedURL];

//    [NSURLConnection sendAsynchronousRequest:feedURLRequest
//            // the NSOperationQueue upon which the handler block will be dispatched:
//                                       queue:[NSOperationQueue mainQueue]
//                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
//                               // back on the main thread, check for errors, if no errors start the parsing
//                               // here we check for any returned NSError from the server, "and" we also check for any http response errors
//                               [self processURLRequest:feedURLRequest data:data response:response error:error block:handler];
//                           }];

    __weak FeedParser *weakSelf = self;
    self.URLSession.configuration.timeoutIntervalForRequest = 10; // set timeout 10s
    _URLSessionDataTask = [self.URLSession dataTaskWithRequest:feedURLRequest
                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                 // back on the main thread, check for errors, if no errors start the parsing
                                                 // here we check for any returned NSError from the server, "and" we also check for any http response errors
                                                 [weakSelf processURLRequest:feedURLRequest data:data response:response error:error block:handler];
                                             }];
    [_URLSessionDataTask resume];
}

- (void)processURLRequest:(NSURLRequest *)feedURLRequest data:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error block:(void (^)(NSError *error))handler {
    if (error != nil) {
        LOGE(@"NSURLConnection error is %@", error);
        handler(error);
    } else {
        // check for any response errors
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        if (([httpResponse statusCode] / 100) == 2) {
            if ([[response MIMEType] isEqual:RSS_MIME_TYPE] || [[response MIMEType] isEqual:RSS_MIME_TYPE_XML]
                    || [[response MIMEType] isEqual:RSS_MIME_TYPE_XML2] || [[response MIMEType] isEqual:ATOM_MIME_TYPE]) {
                // the XML data.
                [self initializeData:data];
                handler(nil);
                return;
            } else if ([[response MIMEType] isEqual:HTML_MIME_TYPE] && self.needHTMLParse) {
                // just parse once.
                _needHTMLParse = false;
                NSURL *url = [self getFeedUrlFromHTML:data];
                if (url != nil) {
                    _feedURL = url;
                    [self goOnRequestAsync:handler];
                }
                return;
            }
        }
        NSString *errorString = [NSString stringWithFormat:@"%@ : %@",
                                                           feedURLRequest.URL, @"Error message displayed when receving a connection error."];
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : errorString};
        NSError *reportError = [NSError errorWithDomain:@"HTTP"
                                                   code:[httpResponse statusCode]
                                               userInfo:userInfo];
        LOGE(@"NSURLConnection http response error is %@, MIMEType : %@", reportError, httpResponse.MIMEType);
        handler(reportError);
    }
}

- (NSURL *)getFeedUrlFromHTML:(NSData *)data {
    TFHpple *doc = [[TFHpple alloc] initWithHTMLData:data];
    NSString *RSS_XPATH = [NSString stringWithFormat:@"//head/link[@type=\"%@\"]", RSS_MIME_TYPE];
    NSString *ATOM_XPATH = [NSString stringWithFormat:@"//head/link[@type=\"%@\"]", ATOM_MIME_TYPE];
    
    TFHppleElement *result = [doc peekAtSearchWithXPathQuery:RSS_XPATH];
    if (result == nil) {
        result = [doc peekAtSearchWithXPathQuery:ATOM_XPATH];
    }
    if (result != nil) {
        NSString *href = [result objectForKey:@"href"];
        if ([href hasPrefix:@"//"]) {
            href = [NSString stringWithFormat:@"%@:%@", _feedURL.scheme, href];
        } else if ([href hasPrefix:@"/"]) {
            href = [NSString stringWithFormat:@"%@%@", _feedURL, href];
        }
        LOGD(@"getFeedUrlFromHTML result: %@", href);
        return [NSURL URLWithString:href];
    }
    return nil;
}

- (void)startParser {
    [self startParserWithStyle:XMLElementStringNormal];
}

- (void)startParserWithStyle:(XMLElementStringStyle)elementStringStyle {
    [self startParserWithStyle:elementStringStyle parseEngine:GDataXMLParseEngine];
}

- (void)startParserWithStyle:(XMLElementStringStyle)elementStringStyle parseEngine:(XMLParseEngine)engine {
    if (_xmlData == nil) {
        LOGW(@"return because xmlData is nil, may be Async NSURLConnection Request is not complete.");
        return;
    }
    // set engine
    _xmlParseEngine = engine;
    // Determine the Class for the parser
    switch (_xmlParseEngine) {
        case GDataXMLParseEngine:
            self.parser = [[GDataRSSParser alloc] initWithData:_xmlData];
            break;
        case NSXMLParseEngine:
            self.parser = [[NSRSSParser alloc] initWithData:_xmlData];
            break;
        default:
            NSAssert1(NO, @"Unknown parser type %ld", _xmlParseEngine);
            break;
    }
    if (self.parser != nil) {
        // Set parser's delegate.
        self.parser.delegate = self;

        // set filter keys
        if (self.blackList != nil) {
            [self.parser setFilterArray:[NSArray arrayWithArray:self.blackList]];
        }

        // start parser
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.parser startParserWithStyle:elementStringStyle];
        });
    }
}

- (void)stopParser {
    // cancel URL Connection first.
    if (self.URLSessionDataTask != nil) {
        [self.URLSessionDataTask cancel];
    }

    if (self.parser != nil) {
        [self.parser stopParser];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parseCompleted:)]) {
            [self.delegate parseCompleted:NO];
        }
    });
}

- (BOOL)isWorking {
    if (self.URLSessionDataTask != nil) {
        NSLog(@"isWorking URLSessionDataTask state : %d", [self.URLSessionDataTask state]);
        if ([self.URLSessionDataTask state] == NSURLSessionTaskStateRunning) {
            return YES;
        }
    }
    if (self.parser != nil) {
        NSLog(@"isWorking parser state : %d", [self.parser isParsing]);
        if ([self.parser isParsing]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark Database function
- (void)findPresetInfoIfNeed:(RSSChannelElement *)element {
    // search it in preset database first
    _presetDB = [PresetFMDBUtil getInstance];
    if (self.presetDB != nil) {
        RSSChannelElement *temp = [self.presetDB getChannelFromURL:element.feedURL.absoluteString];
        if (temp != nil) {
            if (temp.categoryOfElement != nil) {
                element.categoryOfElement = temp.categoryOfElement;
            }
            if (temp.favIconData != nil) {
                element.favIconData = temp.favIconData;
            }
        }
    }
    [_presetDB closeDB];
}

#pragma mark FeedParser (private)

- (void)initializeData:(NSData *)data {
    unsigned long size = [data length];
    LOGD(@"initializeData size : %lu Byte, %lu KB", size, size / 1024);
    _xmlData = data;
}

#pragma mark RSSParserDelegate

- (void)parseErrorOccurred:(NSError *)error {
    LOGE(@"parseErrorOccurred %@, %@", error, self.feedURL);
    [self stopParser];
}

- (void)elementDidParsed:(RSSBaseElement *)element {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(elementDidParsed:)]) {
            element.feedURL = self.feedURL;
            if ([element isKindOfClass:[RSSChannelElement class]]) {
                // find info in preset database.
                [self findPresetInfoIfNeed:(RSSChannelElement *) element];
            }

            [self.delegate elementDidParsed:element];
        }
    });
}

- (void)allElementsDidParsed {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(allElementsDidParsed)]) {
            [self.delegate allElementsDidParsed];
        }
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parseCompleted:)]) {
            [self.delegate parseCompleted:YES];
        }
    });
}

@end
