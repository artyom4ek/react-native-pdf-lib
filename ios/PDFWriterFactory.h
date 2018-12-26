#include <stdio.h>
#include <PDFWriter.h>
#include <PDFPage.h>
#include <PageContentContext.h>
#include <PDFModifiedPage.h>

class PDFWriterFactory {
private:
    PDFWriter* pdfWriter;
    PDFWriterFactory (PDFWriter*);
    void addPages    (NSString* documentPath, NSArray* pageActions);
    void modifyPages (NSString* documentPath, NSArray* pageActions);
    
public:
    static NSString* create (NSDictionary* pages);
    static NSString* modify (NSDictionary* pages);
    
};
