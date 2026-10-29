/*
 * NovaForge AI Game Engine — Native Windows Customized Persian Studio Launcher (Win32 GUI)
 * Zero Python dependency, zero console window (-mwindows -municode).
 * Pre-configures Godot 4.7.2 Portable Self-Contained Mode (`_sc_` + `editor_data/editor_settings-4.7.tres`)
 * with Persian (`fa`) UI, bundled Vazirmatn font, and custom Midnight-Cyan NovaForge theme BEFORE first launch!
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

static const wchar_t* kGodotWinUrl =
    L"https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip";

enum ButtonIds {
    ID_BTN_EDITOR = 101,
    ID_BTN_PLAY   = 102
};

static HWND g_hwndStatus = nullptr;
static HWND g_btnEditor  = nullptr;
static HWND g_btnPlay    = nullptr;
static HBRUSH g_bgBrush  = nullptr;
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

static std::string WideToUtf8(const std::wstring& w) {
    if (w.empty()) return "";
    int sz = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), nullptr, 0, nullptr, nullptr);
    std::string out(sz, '\0');
    WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), &out[0], sz, nullptr, nullptr);
    for (char& c : out) {
        if (c == '\\') c = '/';
    }
    return out;
}

static void WriteUtf8File(const std::wstring& path, const std::string& content) {
    HANDLE hf = CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (hf != INVALID_HANDLE_VALUE) {
        DWORD written = 0;
        if (!content.empty()) {
            WriteFile(hf, content.data(), (DWORD)content.size(), &written, nullptr);
        }
        CloseHandle(hf);
    }
}

static void EnsurePersianPortableSettings(const std::wstring& root) {
    std::wstring binDir = root + L"\\engine_bin";
    std::wstring edData = binDir + L"\\editor_data";
    CreateDirectoryW(binDir.c_str(), nullptr);
    CreateDirectoryW(edData.c_str(), nullptr);

    std::wstring scFile = binDir + L"\\_sc_";
    if (!FileExistsW(scFile)) {
        WriteUtf8File(scFile, "\n");
    }

    std::wstring settingsFile = edData + L"\\editor_settings-4.7.tres";
    {
        std::string regFont = WideToUtf8(root + L"\\fonts\\Vazirmatn-Regular.ttf");
        std::string boldFont = WideToUtf8(root + L"\\fonts\\Vazirmatn-Bold.ttf");
        std::string tres =
            "[gd_resource type=\"EditorSettings\" format=3]\n\n"
            "[resource]\n"
            "interface/editor/localization/editor_language = \"fa\"\n"
            "interface/editor/localization/localize_settings = true\n"
            "interface/editor/fonts/main_font_size = 14\n"
            "interface/editor/fonts/main_font = \"" + regFont + "\"\n"
            "interface/editor/fonts/main_font_bold = \"" + boldFont + "\"\n"
            "interface/theme/style = \"Modern\"\n"
            "interface/theme/color_preset = \"Custom\"\n"
            "interface/theme/follow_system_theme = false\n"
            "interface/theme/use_system_accent_color = false\n"
            "interface/theme/base_color = Color(0.085, 0.11, 0.175, 1)\n"
            "interface/theme/accent_color = Color(0.22, 0.78, 0.98, 1)\n"
            "interface/theme/contrast = 0.28\n"
            "interface/theme/corner_radius = 6\n"
            "interface/theme/border_size = 1\n"
	"interface/theme/draw_extra_borders = true\n"
            "interface/editor/update_continuously = true\n"
            "interface/editor/behavior/show_internal_errors_in_toast_notifications = 0\n";
        WriteUtf8File(settingsFile, tres);
    }
}

struct LaunchRequest {
    HWND hwnd;
    int mode; // 1 = editor, 2 = interactive 3D program/game
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
        SetWindowTextW(g_hwndStatus, L"⏳ در حال دریافت خودکار هسته موتور (فقط بار اول)... لطفاً صبر کنید");

        HRESULT hr = URLDownloadToFileW(nullptr, kGodotWinUrl, zipPath.c_str(), 0, nullptr);
        if (FAILED(hr) || !FileExistsW(zipPath)) {
            SetWindowTextW(g_hwndStatus, L"❌ خطا در دانلود خودکار. اتصال اینترنت را بررسی کنید.");
            EnableWindow(g_btnEditor, TRUE);
            EnableWindow(g_btnPlay, TRUE);
            g_busy = false;
            return 1;
        }

        SetWindowTextW(g_hwndStatus, L"📦 در حال آماده‌سازی فایل اجرایی...");
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

    EnsurePersianPortableSettings(root);

    std::wstring args;
    if (req.mode == 1) {
        args = L"-e --path \"" + root + L"\" scenes/showcase/novaforge_sandbox.tscn";
    } else {
        args = L"--path \"" + root + L"\" res://scenes/showcase/novaforge_sandbox.tscn";
    }

    SetWindowTextW(g_hwndStatus, L"✅ در حال ورود به محیط فارسی نوافورج...");
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
    LaunchRequest* req = new LaunchRequest{ hwnd, mode };
    HANDLE hThread = CreateThread(nullptr, 0, DownloadAndLaunchThread, req, 0, nullptr);
    if (hThread) CloseHandle(hThread);
}

static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_CREATE: {
            g_titleFont = CreateFontW(23, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                                      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                                      DEFAULT_PITCH | FF_SWISS, L"Segoe UI");
            g_subFont   = CreateFontW(15, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                                      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                                      DEFAULT_PITCH | FF_SWISS, L"Segoe UI");
            g_btnFont   = CreateFontW(17, 0, 0, 0, FW_SEMIBOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                                      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                                      DEFAULT_PITCH | FF_SWISS, L"Segoe UI");

            HWND hTitle = CreateWindowW(L"STATIC", L"🚀 موتور بازی‌سازی هوش مصنوعی نوافورج — نسخه ۳.۱ (فارسی)",
                                        WS_VISIBLE | WS_CHILD | SS_CENTER, 25, 22, 520, 32, hwnd, nullptr, nullptr, nullptr);
            SendMessageW(hTitle, WM_SETFONT, (WPARAM)g_titleFont, TRUE);

            HWND hSub = CreateWindowW(L"STATIC",
                L"چت و کدنویسی زنده با هوش مصنوعی 111B + ساخت مش ۳۶۰ درجه واقعی (Hunyuan3D-2) + ریگ خودکار ۱۹ استخوانی",
                WS_VISIBLE | WS_CHILD | SS_CENTER, 20, 58, 530, 36, hwnd, nullptr, nullptr, nullptr);
            SendMessageW(hSub, WM_SETFONT, (WPARAM)g_subFont, TRUE);

            g_btnEditor = CreateWindowW(L"BUTTON",
                L"🛠️  ورود به ویرایشگر فارسی گادوت ۴.۷.۲ (میزکار نوافورج + ساخت مش ۳۶۰ درجه)",
                WS_VISIBLE | WS_CHILD | BS_PUSHBUTTON, 38, 108, 494, 56,
                hwnd, (HMENU)ID_BTN_EDITOR, nullptr, nullptr);
            SendMessageW(g_btnEditor, WM_SETFONT, (WPARAM)g_btnFont, TRUE);

            g_btnPlay = CreateWindowW(L"BUTTON",
                L"🎮  اجرای محیط تعاملی سه‌بعدی و بازی (همراه پنل ساخت مش ۳۶۰ درجه و ریگ زنده)",
                WS_VISIBLE | WS_CHILD | BS_PUSHBUTTON, 38, 178, 494, 54,
                hwnd, (HMENU)ID_BTN_PLAY, nullptr, nullptr);
            SendMessageW(g_btnPlay, WM_SETFONT, (WPARAM)g_btnFont, TRUE);

            const wchar_t* initStatus = FileExistsW(GetGodotExePath())
                ? L"✅ آماده اجرا روی ویندوز (بدون نیاز به پایتون یا نصب؛ اینترنت برای هوش مصنوعی ابری ۳۶۰ درجه)"
                : L"⚡ آماده — با کلیک روی هر دکمه، هسته موتور خودکار دریافت و به فارسی باز می‌شود";

            g_hwndStatus = CreateWindowW(L"STATIC", initStatus,
                WS_VISIBLE | WS_CHILD | SS_CENTER, 25, 252, 520, 38, hwnd, nullptr, nullptr, nullptr);
            SendMessageW(g_hwndStatus, WM_SETFONT, (WPARAM)g_subFont, TRUE);
            return 0;
        }
        case WM_CTLCOLORSTATIC: {
            HDC hdc = (HDC)wParam;
            SetTextColor(hdc, RGB(224, 238, 255));
            SetBkColor(hdc, RGB(16, 21, 34));
            return (INT_PTR)g_bgBrush;
        }
        case WM_COMMAND: {
            int id = LOWORD(wParam);
            if (id == ID_BTN_EDITOR) TriggerLaunch(hwnd, 1);
            else if (id == ID_BTN_PLAY) TriggerLaunch(hwnd, 2);
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

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int nCmdShow) {
    g_bgBrush = CreateSolidBrush(RGB(16, 21, 34));

    WNDCLASSEXW wc = { sizeof(WNDCLASSEXW) };
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInstance;
    wc.hCursor       = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = g_bgBrush;
    wc.lpszClassName = L"NovaForgePersianLauncherWnd";
    RegisterClassExW(&wc);

    int w = 586, h = 345;
    int sx = (GetSystemMetrics(SM_CXSCREEN) - w) / 2;
    int sy = (GetSystemMetrics(SM_CYSCREEN) - h) / 2;

    HWND hwnd = CreateWindowExW(
        0, wc.lpszClassName,
        L"استودیو بازی‌سازی هوش مصنوعی نوافورج — NovaForge AI Studio",
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
    return 0;
}
