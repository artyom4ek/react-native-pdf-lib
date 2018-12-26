#include <Foundation/Foundation.h>
#include <React/RCTConvert.h>
#include <stdexcept>
#include "PDFPageFactory.h"
#include "IByteReaderWithPosition.h"
#include "InputByteArrayStream.h"
#include "InputFileStream.h"
#include "InputStringBufferStream.h"
#include "MyStringBuf.h"

PDFPageFactory::PDFPageFactory (PDFWriter* pdfWriter, PDFPage* page) {
    this->pdfWriter    = pdfWriter;
    this->page         = page;
    this->modifiedPage = nullptr;
}

PDFPageFactory::PDFPageFactory (PDFWriter* pdfWriter, PDFModifiedPage* page) {
    this->pdfWriter    = pdfWriter;
    this->modifiedPage = page;
    this->page         = nullptr;
}

ResourcesDictionary* PDFPageFactory::getResourcesDict () {
    // Determine if we have a PDFPage or a PDFModifiedPage
    if (this->page != nullptr) {
        return &this->page->GetResourcesDictionary();
    }
    else if (this->modifiedPage != nullptr) {
        return this->modifiedPage->GetCurrentResourcesDictionary();
    }
    return nullptr; // This should never happen...
}

void PDFPageFactory::endContext () {
    // Determine if we have a PDFPage or a PDFModifiedPage
    if (this->page != nullptr) {
        pdfWriter->EndPageContentContext((PageContentContext*)context);
        pdfWriter->WritePageAndRelease(page);
    }
    else if (this->modifiedPage != nullptr) {
        modifiedPage->EndContentContext();
        modifiedPage->WritePage();
    }
    else {
        throw std::invalid_argument(@"No pages found - this should never happen!".UTF8String);
    }
}

void PDFPageFactory::createAndWrite (NSString* documentPath, PDFWriter* pdfWriter, NSDictionary* pageActions) {
    PDFPage* page = new PDFPage();
    PDFPageFactory factory(pdfWriter, page);
    
    NumberPair coords = getCoords(pageActions[@"mediaBox"]);
    NumberPair dims   = getDims(pageActions[@"mediaBox"]);
    NSInteger pageIndex = [RCTConvert NSInteger:pageActions[@"pageIndex"]];
    page->SetMediaBox(PDFRectangle(coords.a.intValue, coords.b.intValue, dims.a.intValue, dims.b.intValue));
    
}

void PDFPageFactory::modifyAndWrite (NSString* documentPath, PDFWriter* pdfWriter, NSDictionary* pageActions) {
    NSInteger pageIndex = [RCTConvert NSInteger:pageActions[@"pageIndex"]];
    PDFModifiedPage page(pdfWriter, pageIndex);
    PDFPageFactory factory(pdfWriter, &page);
    
    factory.drawImageOnPdf(documentPath, pageIndex, pageActions[@"actions"]);
}

void PDFPageFactory::drawImageOnPdf(NSString *pdfPath, NSInteger pageIndex, NSArray *imageActions) {
    NSData *oldPdfData = [NSData dataWithContentsOfFile:pdfPath];
    NSURL* oldPdfURL = [NSURL fileURLWithPath:pdfPath];
    
    CGPDFDocumentRef oldPdf = CGPDFDocumentCreateWithURL((CFURLRef)oldPdfURL);
    
    NSMutableData* modifiedPdfData = [NSMutableData new];
    CGDataConsumerRef dataConsumer = CGDataConsumerCreateWithCFData((CFMutableDataRef)modifiedPdfData);
    
    CFMutableDictionaryRef attrDictionary = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrDictionary, kCGPDFContextTitle, CFSTR(""));
    CGContextRef pdfContext = CGPDFContextCreate(dataConsumer, NULL, attrDictionary);
    CFRelease(dataConsumer);
    CFRelease(attrDictionary);
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef) oldPdfData);
    CGPDFDocumentRef modifiedPdf = CGPDFDocumentCreateWithProvider(provider);
    CGDataProviderRelease(provider);
    
    for (int k = 1; k <= CGPDFDocumentGetNumberOfPages(oldPdf); k++) {
        CGPDFPageRef page = CGPDFDocumentGetPage(modifiedPdf, k);
        CGRect pageRect = CGPDFPageGetBoxRect(page, kCGPDFMediaBox);
        CGContextBeginPage(pdfContext, &pageRect);
        CGContextDrawPDFPage(pdfContext, page);
        
        if (k == pageIndex + 1) {
            for (NSDictionary* action in imageActions) {
                NSDictionary* imageInfo = [RCTConvert NSDictionary: action];
                NSString* imagePath = [RCTConvert NSString:imageInfo[@"imagePath"]];
                UIImage* signatureImage = [UIImage imageWithContentsOfFile:imagePath];
                
                NumberPair coordinates = getCoords(imageInfo);
                NumberPair dimensions = getDims(imageInfo);
                
                CGFloat x = [coordinates.a floatValue];
                CGFloat y = [coordinates.b floatValue];
                CGFloat width = [dimensions.a floatValue];
                CGFloat height = [dimensions.b floatValue];
                
                pageRect = CGRectMake(x, y, width, height);
                
                CGImageRef pageImage = [signatureImage CGImage];
                CGContextDrawImage(pdfContext, pageRect, pageImage);
            }
        }
        CGPDFContextEndPage(pdfContext);
    }
    CGPDFContextClose(pdfContext);
    CGContextRelease(pdfContext);
    
    [modifiedPdfData writeToFile:pdfPath atomically:YES];
}

NumberPair PDFPageFactory::getCoords (NSDictionary* coordsMap) {
    return PDFPageFactory::getNumberKeyPair(coordsMap, @"x", @"y");
}

NumberPair PDFPageFactory::getDims (NSDictionary* dimsMap) {
    return PDFPageFactory::getNumberKeyPair(dimsMap, @"width", @"height");
}

NumberPair PDFPageFactory::getNumberKeyPair (NSDictionary* map, NSString* key1, NSString* key2) {
    NSNumber *a = nil;
    NSNumber *b = nil;
    
    if (map[key1] && map[key2]) {
        a = [RCTConvert NSNumber:map[key1]];
        b = [RCTConvert NSNumber:map[key2]];
    }
    
    return NumberPair { a, b };
}

unsigned PDFPageFactory::hexIntFromString (NSString* hexStr) {
    unsigned hexColor = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&hexColor];
    return hexColor;
}
