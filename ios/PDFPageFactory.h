#include <stdio.h>
#include <UIKit/UIKit.h>
#include <PDFWriter.h>
#include <PDFPage.h>
#include <PageContentContext.h>
#include <PDFModifiedPage.h>


typedef struct {
    NSNumber* a;
    NSNumber* b;
} NumberPair;

class PDFPageFactory {
private:
    
    PDFWriter*              pdfWriter;
    PDFPage*                page;
    PDFModifiedPage*        modifiedPage;
    AbstractContentContext* context;
    std::map<NSString*, unsigned long> formXObjectMap;
    
//    PDFPageFactory  (PDFWriter*, AbstractContentContext*);
    PDFPageFactory  (PDFWriter*, PDFPage*);
    PDFPageFactory  (PDFWriter*, PDFModifiedPage*);
    
    ResourcesDictionary* getResourcesDict ();
    void                 endContext       ();
    
    void drawImageOnPdf(NSString* pdfPath, NSInteger pageIndex, NSArray *imageActions);
    
    static NumberPair getCoords         (NSDictionary* coordsMap);
    static NumberPair getDims           (NSDictionary* coordsMap);
    static NumberPair getNumberKeyPair  (NSDictionary* map, NSString* key1, NSString* key2);
    static unsigned   hexIntFromString  (NSString* hexStr);


    
public:
    static void createAndWrite (NSString* documentPath, PDFWriter* pdfWriter, NSDictionary* pageActions);
    static void modifyAndWrite (NSString* documentPath, PDFWriter* pdfWriter, NSDictionary* pageActions);
};
