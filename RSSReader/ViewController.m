//
//  ViewController.m
//  RSSReader
//
//  Created by zhangchao on 15/2/4.
//  Copyright (c) 2015年 zhangchao. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _numberOfRows = 0;

    [_startParseButton setEnabled:false];
    [_xmlSourcePopup addItemsWithTitles:XMLSourceArrays];
    [_elementStringStylePopUp addItemsWithTitles:XMLElementStringStyleArrays];
    [_parseEnginePopup addItemsWithTitles:XMLParseEngineArrays];
    // Do any additional setup after loading the view.
    XMLSource source = (XMLSource) [_xmlSourcePopup indexOfSelectedItem];
    [self checkXmlSourceChoose:source];

    self.feedItemsTableView.delegate = self;
    self.feedItemsTableView.dataSource = self;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)checkXmlSourceChoose:(XMLSource)source {
    NSLog(@"checkXmlSourceChoose index : %d", (int) [_xmlSourcePopup indexOfSelectedItem]);
    if (source == XMLSourceLocalFile) {
        // disable sth.
        [self.loadUrlButton setEnabled:NO];
        [self.openLocalFileButton setEnabled:YES];
        [self.filePathTextField setEditable:NO];
        [self.filePathTextField setStringValue:@""];
    } else if (source == XMLSourceURL) {
        // disable sth.
        [self.openLocalFileButton setEnabled:NO];
        [self.loadUrlButton setEnabled:YES];
        [self.filePathTextField setEditable:YES];
        [self.filePathTextField setStringValue:@"http://rss.cnbeta.com/rss"];
    }
}

- (IBAction)loadUrlButtonPressed:(NSButton *)sender {
    // TODO load Feed data and save data in self.data
    // delete whiteSpace and new line.
    NSString *urlString = [self.filePathTextField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSURL *feedURL = [NSURL URLWithString:urlString];

//    NSError *urlError = nil;
//    _feedParser = [[FeedParser alloc] initWithURLSync:feedURL error:&urlError];
//    _feedParser.delegate = self;
//    NSLog(@"initWithURL error is %@", urlError);
//    _data = [_feedParser.xmlData copy];
//
//    [_startParseButton setEnabled:(_data != nil)];

    _feedParser = [[FeedParser alloc] initWithURLAsync:feedURL completionHandler:^(NSError *error) {
        if (error == nil) {
            _data = [_feedParser.xmlData copy];
            [_startParseButton setEnabled:(_data != nil)];
        }
    }];
    _feedParser.delegate = self;
}

- (IBAction)didXmlSourceChoose:(NSPopUpButton *)sender {
    XMLSource source = (XMLSource) [_xmlSourcePopup indexOfSelectedItem];
    [self checkXmlSourceChoose:source];
}

- (IBAction)openFileButtonPressed:(NSButton *)sender {
    NSLog(@"Button CLicked.");
    
    NSString *path = [self getFilePathFromDialog];
    // show path in Text Field.
    [_filePathTextField setStringValue:(path != nil) ? path : @""];
    if (path != nil) [self clearUIContents];
    
    _data = [self loadDataFromFile:path];
    _feedParser = [[FeedParser alloc] initWithData:_data];
    _feedParser.delegate = self;
    [_startParseButton setEnabled:(_data != nil)];
}

- (IBAction)startParserButtonPressed:(NSButton *)sender {
    [self startParse];
}

- (IBAction)didChannelLinkClicked:(NSButton *)sender {
    NSString *urlString = [_channelLinkButton accessibilityValueDescription];
    [self openURL:urlString];
}

- (void)openURL:(NSString *)urlString {
    if (urlString != nil && [urlString hasPrefix:@"http://"]) {
        NSURL *url = [[NSURL alloc] initWithString:urlString];
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (void) startParse {
    if (_feedParser != nil) {
        [_feedParser stopParser];
    }
    [_feedParser startParserWithStyle:(XMLElementStringStyle) [_elementStringStylePopUp indexOfSelectedItem]
                          parseEngine:(XMLParseEngine) [_parseEnginePopup indexOfSelectedItem]];
}

- (NSData *)loadDataFromFile:(NSString *)path {
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    if (data == nil) {
        NSLog(@"loadDataFromFile data is NULL !!!");
    }
    //    NSString *strData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    //    NSLog(@"loadDataFromFile data is %@", strData);
    return data;
}

- (NSString *)getFilePathFromDialog {
    // Create the File Open Dialog class.
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    //    // Enable the selection of files in the dialog.
    //    [openPanel setCanChooseFiles:YES];
    //    // Multiple files not allowed
    //    [openPanel setAllowsMultipleSelection:NO];
    // Can't select a directory
    [openPanel setCanChooseDirectories:NO];
    // set file type.
    [openPanel setAllowedFileTypes:@[@"xml"]];
    
    NSURL *result = nil;
    
    // single selection
    if ([openPanel runModal] == NSModalResponseOK) {
        result = [openPanel URLs][0];
    }
    
    NSLog(@"getFilePathFromDialog Url: %@", result);
    return result.path;
}

- (void)removeAllObjectsOfTable {
//    [_currentTrackPoints removeAllObjects];
    _numberOfRows = 0;
    [self.feedItemsTableView reloadData];
}

- (void)clearUIContents {
    [self removeAllObjectsOfTable];
    [_channelTitleTextField setStringValue:@""];
    [_channelLinkTextField setStringValue:@""];
    [_channelLinkButton setAccessibilityValueDescription:@""];
    [_channelDescriptionTextField setStringValue:@""];
    [_channelPubDateTextField setStringValue:@""];
    [_channelLanguageTextField setStringValue:@""];
}

#pragma mark - FeedParserDelegate

- (void)elementDidParsed:(RSSBaseElement *)element {
    if (element == nil) {
        NSLog(@"elementDidParsed receive a nil value.");
        return;
    }
    if ([element isKindOfClass:[RSSChannelElement class]]) {
        [_channelLinkTextField setStringValue:element.linkOfElement];
        [_channelLinkButton setAccessibilityValueDescription:element.linkOfElement];
        [_channelLanguageTextField setStringValue:((RSSChannelElement *)element).languageOfChannel];

        if (_useHTMLLabelCheckBox.state == 0) {
            [_channelTitleTextField setStringValue:element.titleOfElement];
            [_channelDescriptionTextField setStringValue:element.descriptionOfElement];
        } else {
            NSAttributedString *attributedStringTitle = [[NSAttributedString alloc]
                    initWithData:[element.titleOfElement dataUsingEncoding:NSUnicodeStringEncoding]
                         options:@{NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType}
              documentAttributes:nil
                           error:nil];
            [_channelTitleTextField setAttributedStringValue:attributedStringTitle];
            NSAttributedString *attributedStringDescription = [[NSAttributedString alloc]
                    initWithData:[element.descriptionOfElement dataUsingEncoding:NSUnicodeStringEncoding]
                         options:@{NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType}
              documentAttributes:nil
                           error:nil];
            [_channelDescriptionTextField setAttributedStringValue:attributedStringDescription];
        }
        [_channelPubDateTextField setStringValue:[RSSSchema convertDate2String:element.pubDateOfElement]];

        _currentChannel = ((RSSChannelElement *) element);
        _numberOfRows = _currentChannel.itemsOfChannel.count;
        NSLog(@"elementDidParsed receive RSSChannelElement. has %ld items", _numberOfRows);
    } else if ([element isKindOfClass:[RSSItemElement class]]) {

    }
    [self.feedItemsTableView reloadData];
}

- (void)allElementsDidParsed {
    NSLog(@"allElementsDidParsed.");
}

#pragma mark - NSTableViewDelegate
- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSUInteger unsignedRow = (NSUInteger) row;
    // Get a new ViewCell
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    if ([tableColumn.identifier isEqualToString:@"ItemID"]) {
        [[cellView textField] setStringValue:[NSString stringWithFormat:@"%ld", unsignedRow + 1]];
    } else if ([tableColumn.identifier isEqualToString:@"ItemDate"]) {
        NSString *dateString = [RSSSchema convertDate2String:((RSSItemElement *) (_currentChannel.itemsOfChannel[unsignedRow])).pubDateOfElement];
        [[cellView textField] setStringValue:dateString];
    } else if ([tableColumn.identifier isEqualToString:@"ItemTitle"]) {
        NSString *title = ((RSSItemElement *) (_currentChannel.itemsOfChannel[unsignedRow])).titleOfElement;
        [[cellView textField] setStringValue:title];
    } else if ([tableColumn.identifier isEqualToString:@"ItemDescription"]) {
        NSString *description = ((RSSItemElement *) (_currentChannel.itemsOfChannel[unsignedRow])).descriptionOfElement;
        [[cellView textField] setStringValue:description];
    }
    return cellView;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _numberOfRows;
}
@end
