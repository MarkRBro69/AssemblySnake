#include <windows.h>
#include <iostream>
#include <tchar.h>

#ifndef GET_X_LPARAM
#define GET_X_LPARAM(lp) ((int)(short)LOWORD(lp))
#endif

#ifndef GET_Y_LPARAM
#define GET_Y_LPARAM(lp) ((int)(short)HIWORD(lp))
#endif

char currentKey = 0;

extern "C" void Read_Msg() {
    MSG msg;
    while (PeekMessage(&msg, NULL, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}

extern "C" void ProcessInput() {
    if (GetAsyncKeyState('W') & 0x8001) {
        currentKey = 'W';
    }
    if (GetAsyncKeyState('A') & 0x8001) {
        currentKey = 'A';
    }
    if (GetAsyncKeyState('S') & 0x8001) {
        currentKey = 'S';
    }
    if (GetAsyncKeyState('D') & 0x8001) {
        currentKey = 'D';
    }
}

extern "C" void Game_Init(HWND hwnd, unsigned char* fieldArray, int fieldArrayLength, char* currentKey);

HFONT hFont;
HPEN hPen;
HBITMAP hBitmap;
HDC hdcMem;

HBRUSH hBrushEmpty = NULL;

int menuSpace = 200;
int margin = 2;
int fieldSize = 20;
int sideSize = 40;

int fieldArrayLength = fieldSize * fieldSize;
unsigned char* fieldArray = new unsigned char[fieldArrayLength];

void DrawField(HDC hdc) {
    int rectX = menuSpace + margin + sideSize;
    int rectY = margin + sideSize;

    for (int i = 0; i < fieldSize; i++) {
        for (int j = 0; j < fieldSize; j++) {
            Rectangle(hdc, rectX, rectY, rectX + sideSize, rectY + sideSize);
            rectX += sideSize;
        }
        rectX = menuSpace + margin + sideSize;
        rectY += sideSize;
    }
}

void DrawElements(HDC hdc) {
    int counter = 0;
    int doubleMargin = margin * 2;
    int rectSize = sideSize - doubleMargin;
    int xOffset = menuSpace + margin + sideSize;
    int yOffset = margin + sideSize;
    int rectX = 0;
    int rectY = 0;

    HBRUSH tempBrush = NULL;

    for (int i = 0; i < fieldSize; i++) {
        for (int j = 0; j < fieldSize; j++) {
            rectX = xOffset + j * sideSize;
            rectY = yOffset + i * sideSize;

            switch (fieldArray[counter]) {
            case 1: tempBrush = CreateSolidBrush(RGB(255, 0, 0)); break;
            case 2: tempBrush = CreateSolidBrush(RGB(0, 0, 255)); break;
            case 3: tempBrush = CreateSolidBrush(RGB(0, 255, 0)); break;
            default: tempBrush = CreateSolidBrush(RGB(0, 0, 0)); break;
            }

            SelectObject(hdc, tempBrush);
            Rectangle(hdc, rectX + doubleMargin, rectY + doubleMargin, rectX + rectSize, rectY + rectSize);
            DeleteObject(tempBrush);
            
            counter++;
        }
    }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE:
        hFont = CreateFont(48, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
            OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, DEFAULT_QUALITY, DEFAULT_PITCH, TEXT("Arial"));
        hPen = CreatePen(PS_SOLID, 2, RGB(255, 255, 255));
        hdcMem = CreateCompatibleDC(NULL);
        break;

    case WM_PAINT: {
        RECT rect;
        GetClientRect(hwnd, &rect);
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);

        if (!hBitmap) {
            HDC hdcScreen = GetDC(hwnd);
            hBitmap = CreateCompatibleBitmap(hdcScreen, rect.right, rect.bottom);
            SelectObject(hdcMem, hBitmap);
            ReleaseDC(hwnd, hdcScreen);
        }

        FillRect(hdcMem, &rect, hBrushEmpty);
        SelectObject(hdcMem, hPen);
        SelectObject(hdcMem, GetStockObject(NULL_BRUSH));

        Rectangle(hdcMem, rect.left + margin, rect.top + margin, menuSpace - margin / 2, rect.bottom - margin);
        Rectangle(hdcMem, rect.left + margin / 2 + menuSpace, rect.top + margin, rect.right - margin, rect.bottom - margin);
        DrawField(hdcMem);
        DrawElements(hdcMem);

        BitBlt(hdc, 0, 0, rect.right, rect.bottom, hdcMem, 0, 0, SRCCOPY);

        EndPaint(hwnd, &ps);
        break;
    }

    case WM_MOUSEMOVE:
        PostMessage(hwnd, WM_USER + 2, wParam, lParam);
        return 0;

    case WM_USER + 2: {
        int x = GET_X_LPARAM(lParam);
        int y = GET_Y_LPARAM(lParam);
        printf("Mouse moved to: %d, %d\n", x, y);
        break;
    }

    case WM_SIZE:
        PostMessage(hwnd, WM_USER + 1, wParam, lParam);
        return 0;

    case WM_USER + 1:
        printf("Window resized: width=%d, height=%d\n", LOWORD(lParam), HIWORD(lParam));
        break;

    case WM_CLOSE:
        DestroyWindow(hwnd);
        break;

    case WM_DESTROY:
        DeleteObject(hFont);
        DeleteObject(hPen);
        DeleteObject(hBitmap);
        DeleteDC(hdcMem);

        PostQuitMessage(0);
        break;

    default:
        return DefWindowProc(hwnd, msg, wParam, lParam);
    }
    return 0;
}

int main() {
    hBrushEmpty = CreateSolidBrush(RGB(0, 0, 0));

    int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    int screenHeight = GetSystemMetrics(SM_CYSCREEN);
    int windowSide = (int)(screenHeight / 1.5);
    int windowOffsetX = (int)((screenWidth - windowSide - menuSpace) / 2);
    int windowOffsetY = (int)(windowSide / 4);

    memset(fieldArray, 0, fieldArrayLength * sizeof(unsigned char));

    WNDCLASSEX wc = { sizeof(WNDCLASSEX), CS_CLASSDC, WndProc, 0L, 0L, GetModuleHandle(NULL),
    NULL, NULL, hBrushEmpty, NULL, _T("MyWindow"), NULL };

    RegisterClassEx(&wc);

    HWND hwnd = CreateWindow(wc.lpszClassName, _T("Hello, Windows!"), WS_OVERLAPPEDWINDOW,
        windowOffsetX, windowOffsetY, windowSide + menuSpace, windowSide, NULL, NULL, wc.hInstance, NULL);

    if (hwnd == NULL) {
        std::cerr << "CreateWindow failed!" << std::endl;
        return 1;  // Завершить программу с ошибкой
    }

    ShowWindow(hwnd, SW_SHOWDEFAULT);
    UpdateWindow(hwnd);

    Game_Init(hwnd, fieldArray, fieldArrayLength, &currentKey);

    DeleteObject(hBrushEmpty);
    delete[] fieldArray;

    return 0;
}
