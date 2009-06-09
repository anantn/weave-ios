@interface NSData (Base64)
-(id) initWithBase64EncodedString:(NSString *) string;
-(NSString *) base64Encoding;
-(NSString *) base64EncodingWithLineLength:(unsigned int) lineLength;
@end
