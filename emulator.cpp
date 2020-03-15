#include <windows.h>
#include <fstream>

LRESULT CALLBACK WindowsCallback(HWND window, UINT message, WPARAM, LPARAM);

struct Bitmap {
     BITMAPINFOHEADER header;
     RGBQUAD palette[2];
};

static const UINT_PTR Timer1(1);

static Bitmap bitmap;

extern "C" void * screen_pixels;
extern "C" void * keyboard_state;

static unsigned char keyboard[256];

static const int width=  640;
static const int height= 480;
static HBITMAP handle=   NULL;

static void CreateScreenMemory();
static void DeleteScreenMemory();

VOID CALLBACK OnTimer(HWND, UINT message, UINT_PTR id, DWORD ticks);

int WINAPI WinMain(HINSTANCE instance, HINSTANCE, LPSTR command, int state)
{
     WNDCLASSEX settings;
     ZeroMemory(&settings, sizeof(WNDCLASSEX));

     settings.cbClsExtra=    NULL;
     settings.cbSize=        sizeof(WNDCLASSEX);
     settings.cbWndExtra=    NULL;
     settings.hbrBackground= (HBRUSH)COLOR_BACKGROUND;
     settings.hCursor=       LoadCursor(NULL, IDC_ARROW);
     settings.hIcon=         NULL;
     settings.hIconSm=       NULL;
     settings.hInstance=     instance;
     settings.lpfnWndProc=   (WNDPROC)WindowsCallback;
     settings.lpszClassName= "MMSE";
     settings.lpszMenuName=  NULL;
     settings.style=         CS_HREDRAW|CS_VREDRAW;

     if (!RegisterClassEx(&settings)) {

          int result= GetLastError();
          MessageBox(NULL,
                     "Window class registration failed",
                     "Registration",
                     MB_ICONERROR);
          ExitProcess(result);
     }

     DWORD style= WS_OVERLAPPEDWINDOW;
     RECT rectangle= {0, 0, width, height};
     AdjustWindowRect(&rectangle, style, FALSE);
     HWND window= CreateWindowEx(NULL, "MMSE", "Memory mapped screen emulator",
                                 style, 200, 200, 
                                 rectangle.right - rectangle.left, 
                                 rectangle.bottom - rectangle.top,
                                 NULL, NULL, instance, NULL);

     if (!window) {

          int result= GetLastError();
          MessageBox(NULL, "Window creation failed", "Creation", MB_ICONERROR);
          ExitProcess(result);
     }

     ShowWindow(window, state);

     MSG message;
     ZeroMemory(&message, sizeof(MSG));

     CreateScreenMemory();

     memset(keyboard, 0, sizeof(keyboard));
     keyboard_state = keyboard;

     SetTimer(window, Timer1, 16, OnTimer);

     while(GetMessage(&message, NULL, 0, 0)) {

          TranslateMessage(&message);
          DispatchMessage(&message);
     }

     KillTimer(window, Timer1);

     DeleteScreenMemory();

     return 0;
}

static int RoundUp(int number, int multiple)
{
     return ((number + multiple - 1) / multiple) * multiple;
}

static void CreateScreenMemory()
{
     int padded= RoundUp(width, 32);
     int stride= padded / 8;

     bitmap.header.biSize=          sizeof(BITMAPINFOHEADER);
     bitmap.header.biWidth=         padded;
     bitmap.header.biHeight=        -height;
     bitmap.header.biPlanes=        1;
     bitmap.header.biBitCount=      1;
     bitmap.header.biCompression=   BI_RGB;
     bitmap.header.biSizeImage=     height * stride;
     bitmap.header.biXPelsPerMeter= 1024;
     bitmap.header.biYPelsPerMeter= 1024;
     bitmap.header.biClrUsed=       2;
     bitmap.header.biClrImportant=  2;
     bitmap.palette[0].rgbRed=      0x00;
     bitmap.palette[0].rgbGreen=    0x00;
     bitmap.palette[0].rgbBlue=     0x00;
     bitmap.palette[1].rgbRed=      0xFF;
     bitmap.palette[1].rgbGreen=    0xFF;
     bitmap.palette[1].rgbBlue=     0xFF;

     handle= CreateDIBSection(NULL, (BITMAPINFO*)&bitmap, DIB_RGB_COLORS, &screen_pixels, NULL, 0);

     memset(screen_pixels, 0x00, height * stride);
}

static void DeleteScreenMemory()
{
     if (handle) {
          
          DeleteObject(handle);
     }
}

static void Paint(HWND window)
{
     PAINTSTRUCT information;
     HDC device= BeginPaint(window, &information);
     if (screen_pixels) {
         
          RECT rectangle;
          GetClientRect(window, &rectangle);
          
          struct {
               int x;
               int y;
               int width;
               int height;
          } output;
          
          output.width= width;
          output.height= height;
          output.x= ((rectangle.right - rectangle.left) - output.width) / 2;
          output.y= ((rectangle.bottom - rectangle.top) - output.height) / 2;
          
          StretchDIBits(device, output.x, output.y, width, 
                        height, 0, 0, width, height, screen_pixels, 
                        (BITMAPINFO*)&bitmap, DIB_RGB_COLORS, SRCCOPY);
     }
     EndPaint(window, &information);
}

extern "C" void machine_code_program();

static void CallMachineCode()
{
     _asm {
          call machine_code_program
     }
}

VOID CALLBACK OnTimer(HWND window, UINT message, UINT_PTR id, DWORD ticks)
{
     switch (id) {

     case Timer1:
          GetKeyboardState(&keyboard[0]);
          CallMachineCode();
          InvalidateRect(window, NULL, FALSE);
          break;
     }
}

LRESULT CALLBACK WindowsCallback(HWND window, UINT message, WPARAM p1, LPARAM p2)
{
     bool processed= false;
     bool invalidate= false;

     switch(message) {

     case WM_PAINT:
          if (GetUpdateRect(window, NULL, FALSE)) {
               
               Paint(window);
          }
          processed= true;
          break;

     case WM_DESTROY:
          PostQuitMessage(0);
          processed= true;
          break;
     }

     return (processed)? 0 : DefWindowProc(window, message, p1, p2);
}
