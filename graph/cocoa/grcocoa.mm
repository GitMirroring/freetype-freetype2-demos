#include "grcocoa.h"
#include "graph.h"
#include <Cocoa/Cocoa.h>
#include <objc/runtime.h>

typedef struct {
    grSurface root;
    NSWindow *window;
    NSBitmapImageRep *bitmapRep;
    NSImageView *imageView;
} grCocoaSurface;

static int gr_cocoa_device_init(void) {
    // initialization for Cocoa
    return 0;
}

static void gr_cocoa_device_done(void) {
    // cleanup
}

static int gr_cocoa_surface_init(grSurface *surface, grBitmap *bitmap) {
    grCocoaSurface *cocoa_surface = (grCocoaSurface *)surface;
    int width = bitmap->width;
    int height = bitmap->rows;

    cocoa_surface->bitmapRep = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL
        pixelsWide:width
        pixelsHigh:height
        bitsPerSample:8
        samplesPerPixel:4
        hasAlpha:YES
        isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace
        bitmapFormat:0
        bytesPerRow:width * 4
        bitsPerPixel:32];

    cocoa_surface->window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, width, height)
        styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
        backing:NSBackingStoreBuffered
        defer:NO];
    [cocoa_surface->window setTitle:@"FreeType Cocoa Demo"];
    cocoa_surface->imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
    [cocoa_surface->imageView setImage:[[NSImage alloc] initWithSize:NSMakeSize(width, height)]];
    [[cocoa_surface->window contentView] addSubview:cocoa_surface->imageView];
    [cocoa_surface->window makeKeyAndOrderFront:nil];

    surface->bitmap = *bitmap;
    return 1;
}

static void gr_cocoa_surface_done(grSurface *surface) {
    grCocoaSurface *cocoa_surface = (grCocoaSurface *)surface;
    [cocoa_surface->window close];
    [cocoa_surface->bitmapRep release];
}

static void gr_cocoa_surface_refresh_rectangle(grSurface *surface, int x, int y, int w, int h) {
    grCocoaSurface *cocoa_surface = (grCocoaSurface *)surface;
    // update the bitmap data here
    unsigned char* bitmap_data = [cocoa_surface->bitmapRep bitmapData];
    for (int row = y; row < y + h; row++) {
        for (int col = x; col < x + w; col++) {
            int pixel_index = (row * cocoa_surface->bitmapRep.bytesPerRow) + (col * 4);
            //update the pixel data
            bitmap_data[pixel_index] = 255; // Red
            bitmap_data[pixel_index + 1] = 255; // Green
            bitmap_data[pixel_index + 2] = 255; // Blue
            bitmap_data[pixel_index + 3] = 255; // Alpha
        }
    }

    [[cocoa_surface->imageView image] addRepresentation:cocoa_surface->bitmapRep];
    [cocoa_surface->imageView setNeedsDisplay:YES];
}

static int gr_cocoa_surface_listen_event(grSurface *surface, int event_mask, grEvent *event) {
    // event handling here
    // return 0 for now
    return 0;
}

static grPixelMode gr_cocoa_pixel_modes[] = {
    gr_pixel_mode_rgb24
};

grDevice gr_cocoa_device = {
    sizeof(grCocoaSurface),
    "cocoa",
    gr_cocoa_device_init,
    gr_cocoa_device_done,
    gr_cocoa_surface_init,
    gr_cocoa_surface_done,
    gr_cocoa_surface_refresh_rectangle,
    gr_cocoa_surface_listen_event,
    -1,
    NULL
};
