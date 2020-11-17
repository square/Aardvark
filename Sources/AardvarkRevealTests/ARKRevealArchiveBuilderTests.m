//
//  Copyright 2020 Square, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <tar.h>
#import <XCTest/XCTest.h>

#import "ARKRevealArchiveBuilder_Testing.h"

#define ARKAssertEqualHeaders(__actual, __expected) \
    { \
        if (![ARKRevealArchiveBuilderTests header:__actual equalsHeader:__expected]) { \
            XCTFail(@"Headers do not match"); \
        } \
    }

@interface ARKRevealArchiveBuilderTests : XCTestCase

@end

@implementation ARKRevealArchiveBuilderTests

#pragma mark - Tests - Header

- (void)testDirectoryHeader;
{
    NSError *error = nil;

    struct header_posix_ustar header = [ARKRevealArchiveBuilder _headerForPath:@"foo/"
                                                                          type:DIRTYPE
                                                                      fileSize:0
                                                                      linkName:nil
                                                              modificationDate:1234
                                                                         error:&error];

    XCTAssertNil(error);

    struct header_posix_ustar expected = {
        /* name */      "foo/",
        /* mode */      {'0', '0', '0', '7', '7', '7', ' ', '\0'},
        /* uid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* gid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* size */      {'0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', ' '},
        /* mtime */     {'0', '0', '0', '0', '0', '0', '0', '2', '3', '2', '2', ' '},
        /* checksum */  {'0', '0', '7', '7', '6', '5', ' ', ' '},
        /* typeflag */  DIRTYPE,
        /* linkname */  {},
        /* magic */     TMAGIC,
        /* version */   TVERSION,
        /* uname */     {},
        /* gname */     {},
        /* devmajor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* devminor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* prefix */    {},
        /* pad */       {}
    };

    ARKAssertEqualHeaders(header, expected);
}

- (void)testFileHeader;
{
    NSError *error = nil;

    struct header_posix_ustar header = [ARKRevealArchiveBuilder _headerForPath:@"foo/file.txt"
                                                                          type:REGTYPE
                                                                      fileSize:5678
                                                                      linkName:nil
                                                              modificationDate:1234
                                                                         error:&error];

    XCTAssertNil(error);

    struct header_posix_ustar expected = {
        /* name */      "foo/file.txt",
        /* mode */      {'0', '0', '0', '7', '7', '7', ' ', '\0'},
        /* uid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* gid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* size */      {'0', '0', '0', '0', '0', '0', '1', '3', '0', '5', '6', ' '},
        /* mtime */     {'0', '0', '0', '0', '0', '0', '0', '2', '3', '2', '2', ' '},
        /* checksum */  {'0', '1', '1', '4', '5', '5', ' ', ' '},
        /* typeflag */  REGTYPE,
        /* linkname */  {},
        /* magic */     TMAGIC,
        /* version */   TVERSION,
        /* uname */     {},
        /* gname */     {},
        /* devmajor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* devminor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* prefix */    {},
        /* pad */       {}
    };

    ARKAssertEqualHeaders(header, expected);
}

- (void)testSymbolicLinkHeader;
{
    NSError *error = nil;

    struct header_posix_ustar header = [ARKRevealArchiveBuilder _headerForPath:@"foo/symlink"
                                                                          type:SYMTYPE
                                                                      fileSize:0
                                                                      linkName:@"path/to/file.txt"
                                                              modificationDate:1234
                                                                         error:&error];

    XCTAssertNil(error);

    struct header_posix_ustar expected = {
        /* name */      "foo/symlink",
        /* mode */      {'0', '0', '0', '7', '7', '7', ' ', '\0'},
        /* uid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* gid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* size */      {'0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', ' '},
        /* mtime */     {'0', '0', '0', '0', '0', '0', '0', '2', '3', '2', '2', ' '},
        /* checksum */  {'0', '1', '4', '4', '2', '5', ' ', ' '},
        /* typeflag */  SYMTYPE,
        /* linkname */  "path/to/file.txt",
        /* magic */     TMAGIC,
        /* version */   TVERSION,
        /* uname */     {},
        /* gname */     {},
        /* devmajor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* devminor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
        /* prefix */    {},
        /* pad */       {}
    };

    ARKAssertEqualHeaders(header, expected);
}

#pragma mark - Tests - File

- (void)testAddDirectory;
{
    ARKRevealArchiveBuilder *archiveBuilder = [[ARKRevealArchiveBuilder alloc] initWithModificationDate:1234];

    NSError *error = nil;

    [archiveBuilder addDirectoryAtPath:@"foo/bar/" error:&error];

    XCTAssertNil(error);

    // The data for a directory should be one block long (only the header).
    XCTAssertEqual([archiveBuilder.archiveData length], 512);

    if ([archiveBuilder.archiveData length] >= 512) {
        struct header_posix_ustar header = {};
        memcpy(&header, [archiveBuilder.archiveData mutableBytes], 512);

        struct header_posix_ustar expected = {
            /* name */      "foo/bar/",
            /* mode */      {'0', '0', '0', '7', '7', '7', ' ', '\0'},
            /* uid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
            /* gid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
            /* size */      {'0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', ' '},
            /* mtime */     {'0', '0', '0', '0', '0', '0', '0', '2', '3', '2', '2', ' '},
            /* checksum */  {'0', '1', '0', '5', '3', '1', ' ', ' '},
            /* typeflag */  DIRTYPE,
            /* linkname */  {},
            /* magic */     TMAGIC,
            /* version */   TVERSION,
            /* uname */     {},
            /* gname */     {},
            /* devmajor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
            /* devminor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
            /* prefix */    {},
            /* pad */       {}
        };

        ARKAssertEqualHeaders(header, expected);
    }
}

- (void)testAddSmallFile;
{
    ARKRevealArchiveBuilder *archiveBuilder = [[ARKRevealArchiveBuilder alloc] initWithModificationDate:1234];

    NSError *error = nil;

    // Arbitrary base64 encoded data with a length of 627 bytes.
    NSData *data = [[NSData alloc] initWithBase64EncodedString:@"TG9yZW0gaXBzdW0gZG9sb3Igc2l0IGFtZXQsIGNvbnNlY3RldHVyIGFkaXBpc2NpbmcgZWxpdC4gRG9uZWMgdml2ZXJyYSwgbmlzaSBhYyBydXRydW0gcnV0cnVtLCB0dXJwaXMgbmVxdWUgY29uZ3VlIGR1aSwgdml0YWUgcmhvbmN1cyBhcmN1IGFyY3UgZXUgbGVjdHVzLiBQZWxsZW50ZXNxdWUgdmFyaXVzIGxhY3VzIGxpZ3VsYSwgYSBwb3N1ZXJlIG1ldHVzIHZ1bHB1dGF0ZSB2aXRhZS4gVml2YW11cyB0ZW1wb3IgdHVycGlzIGV1IGZpbmlidXMgcGhhcmV0cmEuIEluIGhlbmRyZXJpdCBwdWx2aW5hciBvZGlvLCBzZWQgZGljdHVtIG5lcXVlIGFjY3Vtc2FuIHNpdCBhbWV0LiBQcm9pbiBpbiBhdWd1ZSBwcmV0aXVtLCBkaWN0dW0gbGliZXJvIGF0LCBwaGFyZXRyYSBtZXR1cy4gQ3JhcyBwdWx2aW5hciBvcm5hcmUgbGVvIHV0IHVsbGFtY29ycGVyLiBTZWQgdml0YWUgb2RpbyBldSBudW5jIHRpbmNpZHVudCBpYWN1bGlzIHF1aXMgdml0YWUgZGlhbS4gRG9uZWMgY3Vyc3VzLCBsZW8gdml0YWUgc29sbGljaXR1ZGluIHZlaGljdWxhLCBsaWd1bGEgZXJvcyBtb2xsaXMgb3JjaSwgdmVsIHBoYXJldHJhIGxlbyBsZWN0dXMgYSBtZXR1cy4gSW4gYXQgZGlhbSB2ZWwgbGVvIGFsaXF1YW0gZWdlc3Rhcy4K" options:0];

    [archiveBuilder addFileAtPath:@"foo/bar/test.txt" withData:data error:&error];

    XCTAssertNil(error);

    NSData *archiveData = [archiveBuilder archiveData];

    // The data for the file should be three blocks long (one for the header, one for the first 512 bytes, and one for
    // the last 115 bytes plus padding).
    XCTAssertEqual([archiveData length], 1536);

    if ([archiveData length] >= 512) {
        struct header_posix_ustar header = {};
        memcpy(&header, [archiveData bytes], 512);

        struct header_posix_ustar expected = {
            /* name */      "foo/bar/test.txt",
            /* mode */      {'0', '0', '0', '7', '7', '7', ' ', '\0'},
            /* uid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
            /* gid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
            /* size */      {'0', '0', '0', '0', '0', '0', '0', '1', '1', '6', '3', ' '},
            /* mtime */     {'0', '0', '0', '0', '0', '0', '0', '2', '3', '2', '2', ' '},
            /* checksum */  {'0', '1', '2', '2', '5', '5', ' ', ' '},
            /* typeflag */  REGTYPE,
            /* linkname */  {},
            /* magic */     TMAGIC,
            /* version */   TVERSION,
            /* uname */     {},
            /* gname */     {},
            /* devmajor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
            /* devminor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
            /* prefix */    {},
            /* pad */       {}
        };

        ARKAssertEqualHeaders(header, expected);
    }

    NSRange rangeOfFileDataInArchive = [archiveData rangeOfData:data
                                                        options:0
                                                          range:NSMakeRange(0, [archiveData length])];

    XCTAssertEqual(rangeOfFileDataInArchive.location, 512);
    XCTAssertEqual(rangeOfFileDataInArchive.length, 627);
}

- (void)testAddSymlink;
{
    ARKRevealArchiveBuilder *archiveBuilder = [[ARKRevealArchiveBuilder alloc] initWithModificationDate:1234];

    NSError *error = nil;

    [archiveBuilder addSymbolicLinkAtPath:@"foo/symlink" toPath:@"path/to/file" error:&error];

    XCTAssertNil(error);

    // The data for a symlink should be one block long (only the header).
    XCTAssertEqual([archiveBuilder.archiveData length], 512);

    if ([archiveBuilder.archiveData length] >= 512) {
        struct header_posix_ustar header = {};
        memcpy(&header, [archiveBuilder.archiveData mutableBytes], 512);

        struct header_posix_ustar expected = {
            /* name */      "foo/symlink",
            /* mode */      {'0', '0', '0', '7', '7', '7', ' ', '\0'},
            /* uid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
            /* gid */       {'0', '0', '0', '0', '0', '0', ' ', '\0'},
            /* size */      {'0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', ' '},
            /* mtime */     {'0', '0', '0', '0', '0', '0', '0', '2', '3', '2', '2', ' '},
            /* checksum */  {'0', '1', '3', '6', '0', '7', ' ', ' '},
            /* typeflag */  SYMTYPE,
            /* linkname */  "path/to/file",
            /* magic */     TMAGIC,
            /* version */   TVERSION,
            /* uname */     {},
            /* gname */     {},
            /* devmajor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
            /* devminor */  {'0', '0', '0', '0', '0', '0', ' ', '\0'},
            /* prefix */    {},
            /* pad */       {}
        };

        ARKAssertEqualHeaders(header, expected);
    }
}

- (void)testCompleteArchive;
{
    ARKRevealArchiveBuilder *archiveBuilder = [ARKRevealArchiveBuilder new];

    XCTAssertEqual([archiveBuilder.archiveData length], 0);

    NSData *data = [archiveBuilder completeArchive];

    // The archive builder should append two empty blocks (1024 bytes) at the end of the archive.
    XCTAssertEqual([data length], 1024);
}

#pragma mark - Static Methods

+ (BOOL)header:(struct header_posix_ustar)actualHeader equalsHeader:(struct header_posix_ustar)expectedHeader;
{
    const char *actualCharacters = (char *)&actualHeader;
    const char *expectedCharacters = (char *)&expectedHeader;
    const size_t headerLength = sizeof(struct header_posix_ustar);

    for (int i = 0 ; i < headerLength ; i++) {
        if (actualCharacters[i] != expectedCharacters[i]) {
            return NO;
        }
    }

    return YES;
}

@end
