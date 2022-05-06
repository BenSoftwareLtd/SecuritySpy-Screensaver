//
//  MBXMLParser.m
//  MBAtom
//
//  Created by Milo on 09/05/2008.
//  Copyright 2008 Phantom Fish. All rights reserved.
//

#import "MBMarkupParser.h"
#import "DLog.h"


@interface MBMarkupParser ()

- (BOOL)isHTML;
- (BOOL)isTerminated;

@property(readonly, nonatomic) NSString *monitoredNamespaceURI;
@property(readonly, nonatomic) NSMutableArray *namespaceLevels;
@property(readwrite, assign, nonatomic) char *monitoredNamespacePrefix;

static void	startElementCallback(void *context, const xmlChar *name, const xmlChar **attributes);
static void endElementCallback(void *context, const xmlChar *name);
static void charactersCallback(void *context, const xmlChar *characters, int length);
static void	commentCallback(void *context, const xmlChar *value);
static void structuredErrorCallback(void *userData, xmlErrorPtr error);
@end


@implementation MBMarkupParser

- (id)initWithXMLMonitoredNamespaceURI:(NSString *)monitoredNamespaceURI;
{
	self = [super init];
	if (self)
		_monitoredNamespaceURI = [monitoredNamespaceURI copy];
	return self;
}

- (id)initWithHTMLEncoding:(NSString *)encodingName;
{
	self = [super init];
	if (self)
	{
		if (encodingName != nil)
			_encoding = [encodingName copy];
		else _encoding = [@"" retain];        //  mark the fact that this parser is for HTML.
	}
	return self;
}

- (id)init;
{
	return [self initWithXMLMonitoredNamespaceURI:nil];
}

//  NSObject
- (void)dealloc;
{
	[self abortParsing];
	if (_parserContext != NULL)
		xmlFreeParserCtxt(_parserContext);
	[_monitoredNamespaceURI release];
	[_encoding release];
	[_namespaceLevels release];
	if (self.monitoredNamespacePrefix != NULL)
		free(self.monitoredNamespacePrefix);
	[super dealloc];
}

- (BOOL)parseChunk:(NSData *)chunk;
{
	if (_isTerminated)
		return YES;
	if (_parserContext == NULL)
	{
		if ([chunk length] == 0)
		{
			_isTerminated = YES;
			return NO;
		}
		xmlSAXHandler handler;
		bzero(&handler, sizeof(handler));
		handler.startElement = &startElementCallback;
		handler.endElement = &endElementCallback;
		handler.characters = &charactersCallback;
		handler.comment = &commentCallback;
		xmlSetStructuredErrorFunc(xmlGenericErrorContext, &structuredErrorCallback);
		xmlSubstituteEntitiesDefault(1);
		if ([self isHTML] == NO)
		{
			_namespaceLevels = [[NSMutableArray alloc] initWithObjects:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"", @"", @"http://www.w3.org/XML/1998/namespace", @"xml", nil], nil];
			_parserContext = xmlCreatePushParserCtxt(&handler, self, (const char *)[chunk bytes], (int)[chunk length], NULL);
		}
		else
		{
			const char *encoding = ([_encoding length] > 0 ? [_encoding cStringUsingEncoding:NSASCIIStringEncoding] : NULL);
			_parserContext = htmlCreatePushParserCtxt(&handler, self, (const char *)[chunk bytes], (int)[chunk length], NULL, (encoding != NULL ? xmlParseCharEncoding(encoding) : XML_CHAR_ENCODING_NONE));
		}
		if (_parserContext == NULL)
			_isTerminated = YES;
	}
	else if (chunk)
	{
		if ([self isHTML] == NO)
			_isTerminated = (xmlParseChunk(_parserContext, (const char *)[chunk bytes], (int)[chunk length], 0) != 0);
		else _isTerminated = (htmlParseChunk(_parserContext, (const char *)[chunk bytes], (int)[chunk length], 0) != 0);
	}
	else
	{
		BOOL success;
		if ([self isHTML] == NO)
			success = (xmlParseChunk(_parserContext, NULL, 0, 1) == 0);
		else success = (htmlParseChunk(_parserContext, NULL, 0, 1) == 0);
		_isTerminated = YES;
		return success;
	}
	return !_isTerminated;
}

- (void)abortParsing;
{
	if (_isTerminated == NO && _parserContext != NULL)
		xmlStopParser(_parserContext);
	_isTerminated = YES;
}

- (NSString *)namespaceURIForQualifiedName:(const char *)qualifiedName;
{
	NSString *prefix = [[NSString alloc] initWithBytesNoCopy:(void *)qualifiedName length:MBPrefixLengthFromQualifiedName(qualifiedName) encoding:NSUTF8StringEncoding freeWhenDone:NO];
	
	NSString *namespaceURI = nil;
	NSInteger i;
	for (i = [self.namespaceLevels count] - 1; i >= 0 && namespaceURI == nil; i--)
	{
		if ([self.namespaceLevels objectAtIndex:i] == [NSNull null])
			continue;
		namespaceURI = [[self.namespaceLevels objectAtIndex:i] objectForKey:prefix];
	}
	
	[prefix release];
	return namespaceURI;
}

- (NSDictionary *)namespaceURIsByPrefix;
{
	NSMutableDictionary *namespaceURIsByPrefix = [NSMutableDictionary dictionaryWithCapacity:2];
	for (id namespaces in self.namespaceLevels)
	{
		if (namespaces == [NSNull null])
			continue;
		for (NSString *prefix in namespaces)
			[namespaceURIsByPrefix setObject:[namespaces objectForKey:prefix] forKey:prefix];
	}
	return namespaceURIsByPrefix;
}

- (BOOL)isInMonitoredNamespace:(const char *)qualifiedName;
{
	if (self.monitoredNamespacePrefix == NULL)
		return NO;
	else if (self.monitoredNamespacePrefix[0] == '\0')
		return (strchr(qualifiedName, ':') == NULL);        //  YES if qualifiedName is in the default namespace.
	size_t length = strlen(self.monitoredNamespacePrefix);
	return (strncmp(self.monitoredNamespacePrefix, qualifiedName, length) && qualifiedName[length] == ':');
}

//  MBSAXParser ()
- (BOOL)isHTML;
{
	return (_encoding != nil);
}

//  MBSAXParser ()
- (BOOL)isTerminated;
{
	return _isTerminated;
}

//  MBSAXParser ()
static void	startElementCallback(void *context, const xmlChar *name, const xmlChar **attributes)
{	
	if ([(MBMarkupParser *)context isHTML] == NO)
	{
		//  Search for namespace declarations.
		NSMutableDictionary *namespaces = nil;
		if (attributes != NULL)
		{
			NSInteger i;
			for (i = 0; attributes[i] != NULL && attributes[i+1]; i += 2)
			{
				if (strncmp((const char *)attributes[i], "xmlns", 5) == 0)
				{
					const char *prefix = (strlen((const char *)attributes[i]) > 6 ? (const char *)attributes[i] + 6 : "");
					if (strcmp(prefix, "xmlns") != 0)
					{
						NSString *namespaceURI = [NSString stringWithUTF8String:(const char *)attributes[i+1]];
						if (namespaces == nil)
							namespaces = [[NSMutableDictionary alloc] initWithCapacity:1];
						[namespaces setObject:namespaceURI forKey:[NSString stringWithUTF8String:prefix]];
						if ([[(MBMarkupParser *)context monitoredNamespaceURI] isEqualToString:namespaceURI])
						{
							[(MBMarkupParser *)context setMonitoredNamespacePrefix:([(MBMarkupParser *)context monitoredNamespacePrefix] == NULL ? malloc(strlen(prefix) + 1) : realloc([(MBMarkupParser *)context monitoredNamespacePrefix], strlen(prefix) + 1))];
							strcpy([(MBMarkupParser *)context monitoredNamespacePrefix], prefix);
						}
						else if ([(MBMarkupParser *)context monitoredNamespacePrefix] != NULL && strcmp([(MBMarkupParser *)context monitoredNamespacePrefix], prefix) == 0)
						{
							free([(MBMarkupParser *)context monitoredNamespacePrefix]);
							[(MBMarkupParser *)context setMonitoredNamespacePrefix:NULL];
						}
					}
				}
			}
		}
		if (namespaces == nil)
			[[(MBMarkupParser *)context namespaceLevels] addObject:[NSNull null]];
		else [[(MBMarkupParser *)context namespaceLevels] addObject:namespaces];
		[namespaces release];
	}
	
	[[(MBMarkupParser *)context delegate] parser:(MBMarkupParser *)context didStartElement:(const char *)name attributes:(const char **)attributes];
}

//  MBSAXParser ()
static void endElementCallback(void *context, const xmlChar *name)
{
	if ([(MBMarkupParser *)context isHTML] == NO)
	{
		if ([[(MBMarkupParser *)context namespaceLevels] lastObject] != [NSNull null] && [(MBMarkupParser *)context monitoredNamespaceURI] != nil)
		{
			//  the scope of one or more namespaces is ending, so we need to recalculate the monitored prefix.
			if ([(MBMarkupParser *)context monitoredNamespacePrefix] != NULL)
			{
				free([(MBMarkupParser *)context monitoredNamespacePrefix]);
				[(MBMarkupParser *)context setMonitoredNamespacePrefix:NULL];
			}
			NSArray *namespaceLevels = [(MBMarkupParser *)context namespaceLevels];
			NSInteger i;
			for (i = [namespaceLevels count] - 2; i >= 0 && [(MBMarkupParser *)context monitoredNamespacePrefix] == NULL; i--)
			{
				id namespaces = [namespaceLevels objectAtIndex:i];
				if (namespaces == [NSNull null])
					continue;
				for (NSString *prefix in namespaces)
				{
					if ([[namespaces objectForKey:prefix] isEqualToString:[(MBMarkupParser *)context monitoredNamespaceURI]])
					{
						[(MBMarkupParser *)context setMonitoredNamespacePrefix:malloc([prefix lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1)];
						[prefix getCString:[(MBMarkupParser *)context monitoredNamespacePrefix] maxLength:NSUIntegerMax encoding:NSUTF8StringEncoding];
						break;
					}
				}
			}
		}
		[[(MBMarkupParser *)context namespaceLevels] removeLastObject];       //  pop the last namespace level.
	}

	[[(MBMarkupParser *)context delegate] parser:(MBMarkupParser *)context didEndElement:(const char *)name];
}

//  MBSAXParser ()
static void charactersCallback(void *context, const xmlChar *characters, int length)
{
	[[(MBMarkupParser *)context delegate] parser:(MBMarkupParser *)context didParseCharacters:(const char *)characters length:length];
}

//  MBSAXParser ()
static void	commentCallback(void *context, const xmlChar *value)
{
	if ([[(MBMarkupParser *)context delegate] respondsToSelector:@selector(parser:didParseComment:)] == NO)
		return;
	
	[[(MBMarkupParser *)context delegate] parser:(MBMarkupParser *)context didParseComment:(const char *)value];
}

//  MBSAXParser ()
static void structuredErrorCallback(void *userData, xmlErrorPtr error)
{
	//  ignore all errors.
}

@synthesize monitoredNamespaceURI = _monitoredNamespaceURI;
@synthesize namespaceLevels = _namespaceLevels;
@synthesize monitoredNamespacePrefix = _monitoredNamespacePrefix;
@synthesize delegate = _delegate;
@synthesize context = _context;

@end


@implementation NSString (MBXMLParser)

- (NSString *)condensedPlaintextWithMaxLength:(NSUInteger)maxLength characterCount:(NSUInteger *)countPointer;
{
	unichar *buffer = malloc([self length] * sizeof(unichar));
	NSUInteger bufferLength = 0, bufferCap = NSUIntegerMax, characterCount = 0, i;
	for (i = 0; i < [self length]; i++)
	{
		unichar character = [self characterAtIndex:i];
		if ([self rangeOfComposedCharacterSequenceAtIndex:i].location != i)       //  surrogate in a multi-byte character.
		{
			buffer[bufferLength++] = character;
			continue;
		}
		if (characterCount >= maxLength && (characterCount >= 600 || countPointer == NULL))
			break;
		else if (characterCount == maxLength)
			bufferCap = bufferLength;
		if (isspace(character))
		{
			if (bufferLength > 0 && buffer[bufferLength - 1] != ' ')
				buffer[bufferLength++] = ' ';
			else continue;
		}
		else buffer[bufferLength++] = character;
		characterCount++;
	}
	//  check for trailing spaces.
	if (bufferLength > 0 && buffer[bufferLength - 1] == ' ')
		bufferLength--;
	if (bufferCap != NSUIntegerMax && bufferCap > 0 && buffer[bufferCap - 1] == ' ')
		bufferCap--;
	if (countPointer != NULL)
		*countPointer = MIN(characterCount, (i == [self length] && bufferLength > 150 && (buffer[bufferLength - 1] == 0x2026 || (buffer[bufferLength - 3] == '.' && buffer[bufferLength - 2] == '.' && buffer[bufferLength - 1] == '.')) ? 150 : 600));
	bufferLength = MIN(bufferLength, bufferCap);
	if (bufferLength == 0)
	{
		free(buffer);
		return @"";
	}
	buffer = realloc(buffer, bufferLength * sizeof(unichar));
	return [[[NSString alloc] initWithCharactersNoCopy:buffer length:bufferLength freeWhenDone:YES] autorelease];
}

struct MBXMLParserContext
{
	BOOL isXHTML;
	NSUInteger maxLength;
	NSUInteger *countPointer;
	unsigned char *buffer;
	size_t bufferSize;
	NSUInteger bufferLength;
	NSUInteger bufferCap;
	NSUInteger characterCount;
};

- (NSString *)condensedPlaintextFromXHTML:(BOOL)isXHTML maxLength:(NSUInteger)maxLength characterCount:(NSUInteger *)countPointer;
{	
	if ([self length] == 0 || (maxLength == 0 && countPointer == NULL))
	{
		if (countPointer != NULL)
			*countPointer = 0;
		return @"";
	}
	
	struct MBXMLParserContext context;
	context.isXHTML = isXHTML;
	context.maxLength = maxLength;
	context.countPointer = countPointer;
	context.bufferSize = [self maximumLengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	context.buffer = malloc(context.bufferSize);
	context.bufferLength = context.characterCount = 0;
	context.bufferCap = NSUIntegerMax;
	
	MBMarkupParser *parser = (isXHTML ? [[MBMarkupParser alloc] initWithXMLMonitoredNamespaceURI:@"http://www.w3.org/1999/xhtml"] : [[MBMarkupParser alloc] initWithHTMLEncoding:@"UTF-8"]);
	parser.delegate = self;
	parser.context = &context;
	BOOL success = [parser parseChunk:[self dataUsingEncoding:NSUTF8StringEncoding]];
	if (success)
		[parser parseChunk:nil];
	else DLog(@"Failed to parse full condensed plaintext for markup!");
	[parser release];
	
	//  check for trailing spaces.
	if (context.bufferLength > 0 && context.buffer[context.bufferLength - 1] == ' ')
		context.bufferLength--;
	if (context.bufferCap != NSUIntegerMax && context.bufferCap > 0 && context.buffer[context.bufferCap - 1] == ' ')
		context.bufferCap--;
	
	if (success && countPointer != NULL)
		*countPointer = MIN(context.characterCount, (context.characterCount != NSUIntegerMax && context.bufferLength > 150 && ((context.buffer[context.bufferLength - 3] == 0xE2 && context.buffer[context.bufferLength - 2] == 0x80 && context.buffer[context.bufferLength - 1] == 0xA6) || (context.buffer[context.bufferLength - 3] == '.' && context.buffer[context.bufferLength - 2] == '.' && context.buffer[context.bufferLength - 1] == '.')) ? 150 : 600));
	
	context.bufferLength = MIN(context.bufferLength, context.bufferCap);
	if (context.bufferLength == 0)
	{
		free(context.buffer);
		return @"";
	}
	context.buffer = realloc(context.buffer, context.bufferLength);
	return [[[NSString alloc] initWithBytesNoCopy:context.buffer length:context.bufferLength encoding:NSUTF8StringEncoding freeWhenDone:YES] autorelease];
}

//  <MBXMLParserDelegate>
- (void)parser:(MBMarkupParser *)parser didStartElement:(const char *)qualifiedName attributes:(const char **)attributes;
{	
	struct MBXMLParserContext *context = (struct MBXMLParserContext *)parser.context;
	if (context->bufferLength == 0 || context->buffer[context->bufferLength - 1] == ' ')
		return;
	
	const char *localName = qualifiedName;
	if (context->isXHTML)
	{
		if ([parser isInMonitoredNamespace:qualifiedName] == NO)
			return;
		else localName = MBLocalNameFromQualifiedName(qualifiedName);
	}
	
	BOOL shouldAddSpace = NO;
	switch (strlen(localName))
	{
		case 1:
			if (strncmp(localName, "p", 1) == 0)
				shouldAddSpace = YES;
			break;
		case 2:
			if (strncmp(localName, "h", 1) == 0 || strncmp(localName, "br", 2) == 0 || strncmp(localName, "li", 2) == 0 || strncmp(localName, "dt", 2) == 0 || strncmp(localName, "dd", 2) == 0 || strncmp(localName, "th", 2) == 0 || strncmp(localName, "td", 2) == 0)
				shouldAddSpace = YES;
			break;
		case 3:
			if (strncmp(localName, "div", 3) == 0 || strncmp(localName, "pre", 3) == 0)
				shouldAddSpace = YES;
			break;
		case 6:
			if (strncmp(localName, "center", 3) == 0)
				shouldAddSpace = YES;
			break;
		case 7:
			if (strncmp(localName, "address", 3) == 0)
				shouldAddSpace = YES;
			break;
		case 10:
			if (strncmp(localName, "blockquote", 3) == 0)
				shouldAddSpace = YES;
			break;
	}
	
	if (shouldAddSpace)
	{
		if (context->characterCount >= context->maxLength && (context->characterCount >= 600 || context->countPointer == NULL))
		{
			context->characterCount = NSUIntegerMax;     //  more than we can be bothered to count.
			[parser abortParsing];
			return;
		}
		else if (context->characterCount == context->maxLength)
			context->bufferCap = context->bufferLength;
		if (context->bufferLength == context->bufferSize)
		{
			DLog(@"Increasing buffer size for %p to accomodate unexpected parser response!", context->buffer);
			context->buffer = realloc(context->buffer, ++(context->bufferSize));
		}
		context->buffer[context->bufferLength++] = ' ';
		context->characterCount++;
	}
}

//  <MBXMLParserDelegate>
- (void)parser:(MBMarkupParser *)parser didEndElement:(const char *)qualifiedName;
{	
	[self parser:parser didStartElement:qualifiedName attributes:NULL];
}

//  <MBXMLParserDelegate>
- (void)parser:(MBMarkupParser *)parser didParseCharacters:(const char *)characters length:(NSUInteger)length;
{
	struct MBXMLParserContext *context = (struct MBXMLParserContext *)parser.context;
	if (length + context->bufferLength > context->bufferSize)
	{
		DLog(@"Increasing buffer size to accomodate unexpected parser response!");
		context->bufferSize = length + context->bufferLength;
		context->buffer = realloc(context->buffer, context->bufferSize);
	}
	NSInteger i;
	for (i = 0; i < length; i++)
	{
		if ((characters[i] & 0xC0) == 0x80)       //  supplementary byte of a multi-byte character.
		{
			context->buffer[context->bufferLength++] = characters[i];
			continue;
		}
		if (context->characterCount >= context->maxLength && (context->characterCount >= 600 || context->countPointer == NULL))
		{
			context->characterCount = NSUIntegerMax;     //  more than we can be bothered to count.
			[parser abortParsing];
			return;
		}
		else if (context->characterCount == context->maxLength)
			context->bufferCap = context->bufferLength;
		if (isspace(characters[i]))
		{
			if (context->bufferLength > 0 && context->buffer[context->bufferLength - 1] != ' ')
				context->buffer[context->bufferLength++] = ' ';
			else continue;
		}
		else context->buffer[context->bufferLength++] = characters[i];
		context->characterCount++;
	}
}

@end


@implementation NSMutableData (MBSAXParser)

- (void)escapeAndAppendCharacters:(const char *)characters length:(NSUInteger)length;
{
	NSInteger i;
	for (i = 0; i < length; i++)
	{
		switch (characters[i])
		{
			case '\0':
				return;
			case '<':
				[self appendBytes:"&lt;" length:4];
				break;
			case '>':
				[self appendBytes:"&gt;" length:4];
				break;
			case '&':
				[self appendBytes:"&amp;" length:5];
				break;
			case '\'':
				[self appendBytes:"&#39;" length:6];
				break;
			case '\"':
				[self appendBytes:"&quot;" length:6];
				break;
			default:
				[self appendBytes:characters + i length:1];
		}
	}
}

@end


const char * MBLocalNameFromQualifiedName(const char *qualifiedName)
{
	NSInteger i;
	for (i = 0; qualifiedName[i] != '\0'; i++)
	{
		if (qualifiedName[i] == ':')
			return qualifiedName + i + 1;
	}
	return qualifiedName;
}

NSUInteger MBPrefixLengthFromQualifiedName(const char *qualifiedName)
{
	NSInteger i;
	for (i = 0; qualifiedName[i] != '\0'; i++)
	{
		if (qualifiedName[i] == ':')
			return i;
	}
	return 0;
}