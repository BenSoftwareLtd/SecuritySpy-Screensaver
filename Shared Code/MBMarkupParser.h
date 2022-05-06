//
//  MBMarkupParser.h
//  MBAtom
//
//  A SAX-style push parser based on libxml.
//
//  Created by Milo on 09/05/2008.
//  Copyright 2008 Phantom Fish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml2/libxml/parser.h>
#import <libxml2/libxml/HTMLparser.h>
@protocol MBXMLParserDelegate;


@interface MBMarkupParser : NSObject
{
	xmlParserCtxtPtr         _parserContext;
	NSString                *_monitoredNamespaceURI;
	NSString                *_encoding;
	NSMutableArray          *_namespaceLevels;
	char                    *_monitoredNamespacePrefix;
	BOOL                     _isTerminated;
	id <MBXMLParserDelegate> _delegate;
	void                    *_context;
}

- (id)initWithXMLMonitoredNamespaceURI:(NSString *)monitoredNamespaceURI;       //  the monitored namespace is only used to allow the -isInMonitoredNamespace: method.
- (id)initWithHTMLEncoding:(NSString *)encodingName;                            //  encoding should be an IANA encoding name, such as "UTF-8".

- (BOOL)parseChunk:(NSData *)chunk;      //  first call must be with at least 1 byte. Call with chunk == nil to indicate the end of the document has been reached. Returns NO if there was an error.
- (void)abortParsing;

//  the following methods are useless when parsing HTML.
- (NSString *)namespaceURIForQualifiedName:(const char *)qualifiedName;
- (NSDictionary *)namespaceURIsByPrefix;
- (BOOL)isInMonitoredNamespace:(const char *)qualifiedName;                       //  much faster than comparing the result of -namespaceURIForQualifiedName:.

@property(assign, nonatomic) id <MBXMLParserDelegate> delegate;
@property(assign, nonatomic) void *context;

@end


@protocol MBXMLParserDelegate <NSObject>

//  All C strings are in UTF-8 encoding. Don't release the parser from these callbacks, libxml will crash.
@required
- (void)parser:(MBMarkupParser *)parser didStartElement:(const char *)qualifiedName attributes:(const char **)attributes;
- (void)parser:(MBMarkupParser *)parser didEndElement:(const char *)qualifiedName;
- (void)parser:(MBMarkupParser *)parser didParseCharacters:(const char *)characters length:(NSUInteger)length;

@optional
- (void)parser:(MBMarkupParser *)parser didParseComment:(const char *)comment;

@end


@interface NSString (MBXMLParser) <MBXMLParserDelegate>

//  methods for parsing plaintext with extra whitespace stripped from text, HTML, or XHTML. Truncated to the specified number of characters (not bytes). countPointer, if not NULL and if parsing finishes without hiccup, is used to return the number of characters returned but no more than 600 characters are counted, or 150 if the receiver ends "..." or with an ellipsis character.
- (NSString *)condensedPlaintextWithMaxLength:(NSUInteger)maxLength characterCount:(NSUInteger *)countPointer;
- (NSString *)condensedPlaintextFromXHTML:(BOOL)isXHTML maxLength:(NSUInteger)maxLength characterCount:(NSUInteger *)countPointer;

@end


@interface NSMutableData (MBSAXParser)

//  a utility method for generating XML data.
- (void)escapeAndAppendCharacters:(const char *)characters length:(NSUInteger)length;     //  escapes using the built-in XML entities. Stops when a NULL character is encountered.

@end


//  utility functions for extracting namespace information.
const char * MBLocalNameFromQualifiedName(const char *qualifiedName);
NSUInteger MBPrefixLengthFromQualifiedName(const char *qualifiedName);
