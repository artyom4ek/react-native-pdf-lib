#import <Foundation/Foundation.h>
#import "PDFWriterFactory.h"
#import "PDFPageFactory.h"

PDFWriterFactory::PDFWriterFactory (PDFWriter* pdfWriter) {
    this->pdfWriter = pdfWriter;
}

NSString* PDFWriterFactory::create (NSDictionary* documentActions) {
    NSString *path = documentActions[@"path"];
    NSLog(@"%@%@", @"Creating document at: ", path);
    PDFWriter pdfWriter;
    EStatusCode esc;
    PDFWriterFactory factory(&pdfWriter);
    
    esc = pdfWriter.StartPDF(path.UTF8String, ePDFVersion13);
    if (esc == EStatusCode::eFailure) {
        return nil;
    }
    
    // Process pages
//    factory.addPages(path, documentActions[@"pages"]);
    
    esc = pdfWriter.EndPDF();
    if (esc == EStatusCode::eFailure) {
        return nil;
    }
    
    return path;
}

NSString* PDFWriterFactory::modify(NSDictionary* documentActions) {
    NSString *path = documentActions[@"path"];
    NSLog(@"%@%@", @"Creating document at: ", path);
    PDFWriter pdfWriter;
    EStatusCode esc;
    PDFWriterFactory factory(&pdfWriter);
    
    // Empty string to modify in place
    esc = pdfWriter.ModifyPDF(path.UTF8String, ePDFVersion13, @"".UTF8String);
    if (esc == EStatusCode::eFailure) {
        return nil;
    }
    
    // Modify pages
    factory.modifyPages(path, documentActions[@"modifyPages"]);
    
    esc = pdfWriter.EndPDF();
    if (esc == EStatusCode::eFailure) {
        return nil;
    }
    
    return path ;
}

void PDFWriterFactory::addPages (NSString* documentPath, NSArray* pages) {
    for (NSDictionary *pageActions in pages) {
        PDFPageFactory::createAndWrite(documentPath, pdfWriter, pageActions);
    }
}

void PDFWriterFactory::modifyPages (NSString* documentPath, NSArray* pages) {
    for (NSDictionary *pageActions in pages) {
        PDFPageFactory::modifyAndWrite(documentPath, pdfWriter, pageActions);
    }
}
