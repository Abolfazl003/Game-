/*
 * NovaForge AI Game Engine — Native Windows Graphical Studio Launcher (Win32 GUI)
 * Zero Python dependency, zero console window (-mwindows -municode).
 * Detects or auto-downloads official Godot 4.7.2 (MIT) and launches Editor, Game, or Project Manager with 1 click.
 */
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <shellapi.h>
#include <urlmon.h>
#include <string>

#pragma comment(lib, "urlmon.lib")
#pragma comment(lib, "shell32.lib")

static const wchar_t* kGodotWinUrl =
    L"https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip";

enum ButtonIds {
    ID_BTN_EDITOR = 101,
    ID_BTN_PLAY   = 102,
    ID_BTN_PM     = 103
};

static HWND g_hwndStatus = nullptr;
static HWND g_btnEditor  = nullptr;
static HWND g_btnPlay    = nullptr;
static HWND g_btnPM      = nullptr;
static HBRUSH g_bgBrush  = nullptr;
static HBRUSH g_cardBrush = nullptr;
static HFONT g_titleFont = nullptr;
static HFONT g_subFont   = nullptr;
static HFONT g_btnFont   = nullptr;
static bool g_busy       = false;

static std::wstring GetAppRootDir() {
    wchar_t buf[MAX_PATH] = {0};
    GetModuleFileNameW(nullptr, buf, MAX_PATH);
    std::wstring path(buf);
    size_t pos = path.find_last_of(L"\\/");
    return (pos != std::wstring::npos) ? path.substr(0, pos) : L".";
}

static std::wstring GetGodotExePath() {
    return GetAppRootDir() + L"\\engine_bin\\Godot_v4.7.2-stable_win64.exe";
}

static bool FileExistsW(const std::wstring& p) {
    DWORD attr = GetFileAttributesW(p.c_str());
    return (attr != INVALID_FILE_ATTRIBUTES && !(attr & FILE_ATTRIBUTE_DIRECTORY));
}

struct LaunchRequest {
    HWND hwnd;
    int mode; // 1 = editor, 2 = play, 3 = project manager
};

static DWORD WINAPI DownloadAndLaunchThread(LPVOID param) {
    LaunchRequest req = *reinterpret_cast<LaunchRequest*>(param);
    delete reinterpret_cast<LaunchRequest*>(param);

    std::wstring root = GetAppRootDir();
    std::wstring binDir = root + L"\\engine_bin";
    std::wstring godotExe = GetGodotExePath();

    if (!FileExistsW(godotExe)) {
        CreateDirectoryW(binDir.c_str(), nullptr);
        std::wstring zipPath = binDir + L"\\godot_4_7_2.zip";
        SetWindowTextW(g_hwndStatus, L"⏳ در حال دانلود خودکار هسته گادوت ۴.۷.۲ (فقط بار اول)... لطفاً چند لحظه صبر کنید");

        HRESULT hr = URLDownloadToFileW(nullptr, kGodotWinUrl, zipPath.c_str(), 0, nullptr);
        if (FAILED(hr) || !FileExistsW(zipPath)) {
            SetWindowTextW(g_hwndStatus, L"❌ خطا در دانلود خودکار. اتصال اینترنت را بررسی کنید.");
            EnableWindow(g_btnEditor, TRUE);
            EnableWindow(g_btnPlay, TRUE);
            EnableWindow(g_btnPM, TRUE);
            g_busy = false;
            return 1;
        }

        SetWindowTextW(g_hwndStatus, L"📦 در حال استخراج فایل اجرایی موتور گادوت ۴.۷.۲...");
        std::wstring psCmd = L"-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command \"Expand-Archive -Force -LiteralPath '" +
                             zipPath + L"' -DestinationPath '" + binDir + L"'\"";
        SHELLEXECUTEINFOW sei = { sizeof(sei) };
        sei.fMask = SEE_MASK_NOCLOSEPROCESS;
        sei.lpVerb = L"open";
        sei.lpFile = L"powershell.exe";
        sei.lpParameters = psCmd.c_str();
        sei.nShow = SW_HIDE;
        if (ShellExecuteExW(&sei) && sei.hProcess) {
            WaitForSingleObject(sei.hProcess, INFINITE);
            CloseHandle(sei.hProcess);
        }
        DeleteFileW(zipPath.c_str());
    }

    if (!FileExistsW(godotExe)) {
        SetWindowTextW(g_hwndStatus, L"❌ فایل اجرایی Godot پیدا نشد.");
        EnableWindow(g_btnEditor, TRUE);
        EnableWindow(g_btnPlay, TRUE);
        EnableWindow(g_btnPM, TRUE);
        g_busy = false;
        return 1;
    }

    std::wstring args;
    if (req.mode == 1) {
        args = L"-e --path \"" + root + L"\" scenes/showcase/novaforge_sandbox.tscn";
    } else if (req.mode == 2) {
        args = L"--path \"" + root + L"\" res://scenes/showcase/novaforge_sandbox.tscn";
    } else {
        args = L"--project-manager";
    }

    SetWindowTextW(g_hwndStatus, L"✅ در حال باز کردن محیط اصلی برنامه...");
    ShellExecuteW(nullptr, L"open", godotExe.c_str(), args.c_str(), root.c_str(), SW_SHOWNORMAL);
    Sleep(700);
    PostMessageW(req.hwnd, WM_CLOSE, 0, 0);
    return 0;
}

static void TriggerLaunch(HWND hwnd, int mode) {
    if (g_busy) return;
    g_busy = true;
    EnableWindow(g_btnEditor, FALSE);
    EnableWindow(g_btnPlay, FALSE);
    EnableWindow(g_btnPM, FALSE);

    LaunchRequest* req = new LaunchRequest{ hwnd, mode };
    HANDLE hThread = CreateThread(nullptr, 0, DownloadAndLaunchThread, req, 0, nullptr);
    if (hThread) CloseHandle(hThread);
}

static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_CREATE: {
            g_titleFont = CreateFontW(24, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                                      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                                      DEFAULT_PITCH | FF_SWISS, L"Segoe UI");
            g_subFont   = CreateFontW(15, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                                      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                                      DEFAULT_PITCH | FF_SWISS, L"Segoe UI");
            g_btnFont   = CreateFontW(17, 0, 0, 0, FW_SEMIBOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                                      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                                      DEFAULT_PITCH | FF_SWISS, L"Segoe UI");

            HWND hTitle = CreateWindowW(L"STATIC", L"NovaForge AI Game Engine (Godot 4.7.2)",
                                        WS_VISIBLE | WS_CHILD | SS_CENTER, 25, 22, 510, 32, hwnd, nullptr, nullptr, nullptr);
            SendMessageW(hTitle, WM_SETFONT, (WPARAM)g_titleFont, TRUE);

            HWND hSub = CreateWindowW(L"STATIC",
                L"رابط کاربری رسمی گادوت ۴ + ماژول‌های هوش مصنوعی لوکال Colibrì و Blueprint/C++",
                WS_VISIBLE | WS_CHILD | SS_CENTER, 25, 58, 510, 24, hwnd, nullptr, nullptr, nullptr);
            SendMessageW(hSub, WM_SETFONT, (WPARAM)g_subFont, TRUE);

            g_btnEditor = CreateWindowW(L"BUTTON",
                L"🚀  ورود مستقیم به ادیتور موتور بازی‌سازی  (Open Godot 4 Editor)",
                WS_VISIBLE | WS_CHILD | BS_PUSHBUTTON, 45, 102, 470, 54,
                hwnd, (HMENU)ID_BTN_EDITOR, nullptr, nullptr);
            SendMessageW(g_btnEditor, WM_SETFONT, (WPARAM)g_btnFont, TRUE);

            g_btnPlay = CreateWindowW(L"BUTTON",
                L"🎮  اجرای مستقیم بازی سه‌بعدی آماده  (Play 3D Showcase)",
                WS_VISIBLE | WS_CHILD | BS_PUSHBUTTON, 45, 168, 470, 48,
                hwnd, (HMENU)ID_BTN_PLAY, nullptr, nullptr);
            SendMessageW(g_btnPlay, WM_SETFONT, (WPARAM)g_btnFont, TRUE);

            g_btnPM = CreateWindowW(L"BUTTON",
                L"📁  ساخت بازی جدید / مدیریت پروژه‌ها  (Project Manager)",
                WS_VISIBLE | WS_CHILD | BS_PUSHBUTTON, 45, 228, 470, 44,
                hwnd, (HMENU)ID_BTN_PM, nullptr, nullptr);
            SendMessageW(g_btnPM, WM_SETFONT, (WPARAM)g_subFont, TRUE);

            const wchar_t* initStatus = FileExistsW(GetGodotExePath())
                ? L"✅ آماده اجرا بدون نیاز به نصب — روی دکمه بالا کلیک کنید"
                : L"⚡ آماده — با کلیک روی دکمه، هسته گادوت ۴.۷.۲ خودکار دریافت و اجرا می‌شود";

            g_hwndStatus = CreateWindowW(L"STATIC", initStatus,
                WS_VISIBLE | WS_CHILD | SS_CENTER, 25, 294, 510, 40, hwnd, nullptr, nullptr, nullptr);
            SendMessageW(g_hwndStatus, WM_SETFONT, (WPARAM)g_subFont, TRUE);
            return 0;
        }
        case WM_CTLCOLORSTATIC: {
            HDC hdc = (HDC)wParam;
            SetTextColor(hdc, RGB(230, 236, 248));
            SetBkColor(hdc, RGB(24, 28, 38));
            return (INT_PTR)g_bgBrush;
        }
        case WM_COMMAND: {
            int id = LOWORD(wParam);
            if (id == ID_BTN_EDITOR) TriggerLaunch(hwnd, 1);
            else if (id == ID_BTN_PLAY) TriggerLaunch(hwnd, 2);
            else if (id == ID_BTN_PM) TriggerLaunch(hwnd, 3);
            return 0;
        }
        case WM_DESTROY:
            if (g_titleFont) DeleteObject(g_titleFont);
            if (g_subFont) DeleteObject(g_subFont);
            if (g_btnFont) DeleteObject(g_btnFont);
            PostQuitMessage(0);
            return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR lpCmdLine, int nCmdShow) {
    std::wstring cmd(lpCmdLine ? lpCmdLine : L"");
    if (cmd.find(L"--direct") != std::wstring::npos && FileExistsW(GetGodotExePath())) {
        std::wstring root = GetAppRootDir();
        std::wstring args = L"-e --path \"" + root + L"\" scenes/showcase/novaforge_sandbox.tscn";
        ShellExecuteW(nullptr, L"open", GetGodotExePath().c_str(), args.c_str(), root.c_str(), SW_SHOWNORMAL);
        return 0;
    }

    g_bgBrush = CreateSolidBrush(RGB(24, 28, 38));
    g_cardBrush = CreateSolidBrush(RGB(36, 42, 56));

    WNDCLASSEXW wc = { sizeof(WNDCLASSEXW) };
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInstance;
    wc.hCursor       = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = g_bgBrush;
    wc.lpszClassName = L"NovaForgeStudioLauncherWnd";
    RegisterClassExW(&wc);

    int w = 576, h = 385;
    int sx = (GetSystemMetrics(SM_CXSCREEN) - w) / 2;
    int sy = (GetSystemMetrics(SM_CYSCREEN) - h) / 2;

    HWND hwnd = CreateWindowExW(
        0, wc.lpszClassName,
        L"NovaForge AI Game Engine — Studio Launcher",
        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
        sx, sy, w, h, nullptr, nullptr, hInstance, nullptr
    );

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    DeleteObject(g_bgBrush);
    DeleteObject(g_cardBrush);
    return 0;
}
