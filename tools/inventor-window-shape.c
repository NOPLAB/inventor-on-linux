/* SPDX-License-Identifier: MIT */
/* Inventor on XWayland can retain an old rectangular bounding mask after a
 * resize, although both the Win32 client and swapchain have the new size.
 * Only remove stale, full-origin rectangular masks on Inventor's main frame.
 * Dialogs, nonrectangular masks, input masks and other applications are untouched.
 */
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/extensions/shape.h>
#include <sys/file.h>
#include <sys/prctl.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
static Display *display;
static Window tracked[32];
static unsigned int tracked_count;
static int shape_event;
static int ignore_destroyed(Display *d, XErrorEvent *e) { (void)d; (void)e; return 0; }
static int is_tracked(Window w)
{
    unsigned int i;
    for (i=0;i<tracked_count;i++) if (tracked[i]==w) return 1;
    return 0;
}
static void repair(Window w)
{
    XWindowAttributes a;
    XRectangle *rectangles;
    int count, ordering;
    if (!XGetWindowAttributes(display,w,&a) || a.map_state!=IsViewable || a.width<=1 || a.height<=1) return;
    rectangles=XShapeGetRectangles(display,w,ShapeBounding,&count,&ordering);
    if (rectangles && count==1 && rectangles[0].x==0 && rectangles[0].y==0 &&
        (rectangles[0].width!=a.width || rectangles[0].height!=a.height))
    {
        XShapeCombineMask(display,w,ShapeBounding,0,0,None,ShapeSet);
        XFlush(display);
        fprintf(stderr,"Restored Inventor drawing mask: %ux%u -> %dx%d\n",
                rectangles[0].width,rectangles[0].height,a.width,a.height);
    }
    if (rectangles) XFree(rectangles);
}
static void consider(Window w)
{
    XClassHint hint={0};
    Window owner=None;
    int match=0, format;
    Atom type;
    unsigned long items, after;
    unsigned char *value=NULL;
    if (is_tracked(w)) { repair(w); return; }
    if (tracked_count>=sizeof(tracked)/sizeof(tracked[0])) return;
    if (XGetTransientForHint(display,w,&owner) && owner!=None) return;
    if (XGetClassHint(display,w,&hint) && hint.res_class && !strcasecmp(hint.res_class,"inventor.exe") &&
        XGetWindowProperty(display,w,XInternAtom(display,"_NET_WM_NAME",False),0,512,False,
                           AnyPropertyType,&type,&format,&items,&after,&value)==Success &&
        format==8 && value && !strncmp((char *)value,"Autodesk Inventor Professional",30)) match=1;
    if (hint.res_name) XFree(hint.res_name);
    if (hint.res_class) XFree(hint.res_class);
    if (value) XFree(value);
    if (!match) return;
    tracked[tracked_count++]=w;
    fprintf(stderr,"Watching Inventor main window 0x%lx\n",w);
    XSelectInput(display,w,StructureNotifyMask|PropertyChangeMask);
    XShapeSelectInput(display,w,ShapeNotifyMask);
    repair(w);
}
int main(void)
{
    Window root,parent,*children=NULL;
    unsigned int count,i;
    XEvent event;
    int fd,shape_error;
    char lock[1024];
    const char *runtime=getenv("XDG_RUNTIME_DIR");
    if (!runtime) return 1;
    snprintf(lock,sizeof(lock),"%s/inventor-window-shape.lock",runtime);
    fd=open(lock,O_CREAT|O_RDWR|O_CLOEXEC,0600);
    if (fd<0) return 1;
    if (flock(fd,LOCK_EX|LOCK_NB)) { close(fd); return 0; }
    prctl(PR_SET_NAME,"inventor-shape",0,0,0);
    if (!(display=XOpenDisplay(NULL))) return 1;
    XSetErrorHandler(ignore_destroyed);
    if (!XShapeQueryExtension(display,&shape_event,&shape_error)) return 1;
    root=DefaultRootWindow(display);
    XSelectInput(display,root,SubstructureNotifyMask);
    if (XQueryTree(display,root,&root,&parent,&children,&count))
    {
        for (i=0;i<count;i++) consider(children[i]);
        if (children) XFree(children);
    }
    for (;;)
    {
        XNextEvent(display,&event);
        if (event.type==MapNotify) consider(event.xmap.window);
        else if (event.type==ConfigureNotify && is_tracked(event.xconfigure.window)) repair(event.xconfigure.window);
        else if (event.type==shape_event+ShapeNotify)
        {
            XShapeEvent *shape=(XShapeEvent *)&event;
            if (shape->kind==ShapeBounding && is_tracked(shape->window)) repair(shape->window);
        }
        else if (event.type==DestroyNotify)
        {
            for (i=0;i<tracked_count;i++) if (tracked[i]==event.xdestroywindow.window)
            { tracked[i]=tracked[--tracked_count]; break; }
        }
    }
}
