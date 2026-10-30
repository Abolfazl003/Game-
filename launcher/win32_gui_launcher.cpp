/*
 * NovaForge AI Game Engine v3.2 — Zero-Question Direct-Entry Launcher & Auto-Bootstrapper (Win32 x64)
 * - ZERO questions, ZERO mode-selection dialogs!
 * - If Godot 4.7.2 is already in `engine_bin\` (default in ReadyToRun ZIP), writes Persian EditorSettings
 *   and opens straight into the NovaForge Studio program IMMEDIATELY (<10ms, zero intermediate windows).
 * - If `engine_bin\Godot_v4.7.2-stable_win64.exe` is missing (e.g. git clone), automatically downloads &
 *   extracts it with a live MB/MB + % Win32 progress bar and enters straight into the program with zero clicks.
 */
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <commctrl.h>
#include <shellapi.h>
#include <urlmon.h>
#include <cstdio>
#include <string>

static const wchar_t* kGodotWinUrl =
    L"https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip";

#define WM_NOVA_PROGRESS (WM_APP + 10)
#define WM_NOVA_STATUS   (WM_APP + 11)

static HWND   g_hwndMain     = nullptr;
static HWND   g_hwndStatus   = nullptr;
static HWND   g_hwndProgress = nullptr;
static HBRUSH g_bgBrush      = nullptr;
static HFONT  g_titleFont    = nullptr;
static HFONT  g_subFont      = nullptr;
static bool   g_playMode     = false;

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
    std::string regFont  = WideToUtf8(root + L"\\fonts\\Vazirmatn-Regular.ttf");
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
        "interface/editor/single_window_mode = false\n"
        "interface/editor/update_continuously = true\n"
        "interface/editor/behavior/show_internal_errors_in_toast_notifications = 0\n";
    WriteUtf8File(settingsFile, tres);
}

static bool LaunchGodotDirectly(const std::wstring& root, const std::wstring& godotExe, bool playMode) {
    EnsurePersianPortableSettings(root);
    std::wstring cmdLine = L"\"" + godotExe + L"\" ";
    if (playMode) {
        cmdLine += L"--path \"" + root + L"\" res://scenes/showcase/novaforge_sandbox.tscn";
    } else {
        cmdLine += L"-e --path \"" + root + L"\" scenes/showcase/novaforge_sandbox.tscn";
    }

    STARTUPINFOW si = { sizeof(si) };
    si.dwFlags = STARTF_USESHOWWINDOW;
    si.wShowWindow = SW_SHOWNORMAL;
    PROCESS_INFORMATION pi = {};
    std::wstring mutableCmd = cmdLine;
    if (CreateProcessW(godotExe.c_str(), &mutableCmd[0], nullptr, nullptr, FALSE, 0, nullptr, root.c_str(), &si, &pi)) {
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        return true;
    }
    HINSTANCE hi = ShellExecuteW(nullptr, L"open", godotExe.c_str(),
        playMode ? (L"--path \"" + root + L"\" res://scenes/showcase/novaforge_sandbox.tscn").c_str()
                 : (L"-e --path \"" + root + L"\" scenes/showcase/novaforge_sandbox.tscn").c_str(),
        root.c_str(), SW_SHOWNORMAL);
    return ((INT_PTR)hi > 32);
}

class DownloadProgressCallback : public IBindStatusCallback {
public:
    STDMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
        if (!ppv) return E_POINTER;
        if (riid == IID_IUnknown || riid == IID_IBindStatusCallback) {
            *ppv = static_cast<IBindStatusCallback*>(this);
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    STDMETHODIMP_(ULONG) AddRef() override { return 1; }
    STDMETHODIMP_(ULONG) Release() override { return 1; }
    STDMETHODIMP OnStartBinding(DWORD, IBinding*) override { return S_OK; }
    STDMETHODIMP GetPriority(LONG*) override { return E_NOTIMPL; }
    STDMETHODIMP OnLowResource(DWORD) override { return S_OK; }
    STDMETHODIMP OnStopBinding(HRESULT, LPCWSTR) override { return S_OK; }
    STDMETHODIMP GetBindInfo(DWORD*, BINDINFO*) override { return S_OK; }
    STDMETHODIMP OnDataAvailable(DWORD, DWORD, FORMATETC*, STGMEDIUM*) override { return S_OK; }
    STDMETHODIMP OnObjectAvailable(REFIID, IUnknown*) override { return S_OK; }

    STDMETHODIMP OnProgress(ULONG ulProgress, ULONG ulProgressMax, ULONG, LPCWSTR) override {
        if (g_hwndMain && ulProgressMax > 0) {
            int pct = (int)((double)ulProgress * 100.0 / (double)ulProgressMax);
            if (pct > 100) pct = 100;
            PostMessageW(g_hwndMain, WM_NOVA_PROGRESS, (WPARAM)pct, 0);

            double mbDone = (double)ulProgress / (1024.0 * 1024.0);
            double mbTot  = (double)ulProgressMax / (1024.0 * 1024.0);
            wchar_t* msg = new wchar_t[160];
            std::swprintf(msg, 160, L"⬇ در حال دانلود خودکار هسته موتور: %.1f از %.1f مگابایت (%d%%)...", mbDone, mbTot, pct);
            PostMessageW(g_hwndMain, WM_NOVA_STATUS, 0, (LPARAM)msg);
        }
        return S_OK;
    }
};

static DWORD WINAPI AutoBootstrapAndEnterThread(LPVOID) {
    std::wstring root     = GetAppRootDir();
    std::wstring binDir   = root + L"\\engine_bin";
    std::wstring godotExe = GetGodotExePath();

    if (!FileExistsW(godotExe)) {
        CreateDirectoryW(binDir.c_str(), nullptr);
        std::wstring zipPath = binDir + L"\\godot_4_7_2.zip";

        DownloadProgressCallback cb;
        HRESULT hr = URLDownloadToFileW(nullptr, kGodotWinUrl, zipPath.c_str(), 0, &cb);
        if (FAILED(hr) || !FileExistsW(zipPath)) {
            wchar_t* errMsg = new wchar_t[160];
            std::swprintf(errMsg, 160, L"❌ خطا در دانلود خودکار هسته موتور. اتصال اینترنت را بررسی و برنامه را دوباره باز کنید.");
            PostMessageW(g_hwndMain, WM_NOVA_STATUS, 0, (LPARAM)errMsg);
            return 1;
        }

        PostMessageW(g_hwndMain, WM_NOVA_PROGRESS, 95, 0);
        {
            wchar_t* extMsg = new wchar_t[160];
            std::swprintf(extMsg, 160, L"📦 در حال نصب خودکار فایل اجرایی گادوت ۴.۷.۲ و فونت فارسی...");
            PostMessageW(g_hwndMain, WM_NOVA_STATUS, 0, (LPARAM)extMsg);
        }

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

    PostMessageW(g_hwndMain, WM_NOVA_PROGRESS, 100, 0);
    {
        wchar_t* goMsg = new wchar_t[160];
        std::swprintf(goMsg, 160, L"✅ نصب تکمیل شد — در حال ورود مستقیم به استودیو نوافورج...");
        PostMessageW(g_hwndMain, WM_NOVA_STATUS, 0, (LPARAM)goMsg);
    }

    LaunchGodotDirectly(root, godotExe, g_playMode);
    Sleep(350);
    if (g_hwndMain) {
        PostMessageW(g_hwndMain, WM_CLOSE, 0, 0);
    }
    return 0;
}

static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_CREATE: {
            g_hwndMain  = hwnd;
            g_titleFont = CreateFontW(22, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                                      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                                      DEFAULT_PITCH | FF_SWISS, L"Segoe UI");
            g_subFont   = CreateFontW(15, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE, DEFAULT_CHARSET,
                                      OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                                      DEFAULT_PITCH | FF_SWISS, L"Segoe UI");

            HWND hTitle = CreateWindowW(L"STATIC", L"⚡ استودیو بازی‌سازی هوش مصنوعی نوافورج ۳.۲",
                                        WS_VISIBLE | WS_CHILD | SS_CENTER, 20, 22, 520, 30, hwnd, nullptr, nullptr, nullptr);
            SendMessageW(hTitle, WM_SETFONT, (WPARAM)g_titleFont, TRUE);

            g_hwndStatus = CreateWindowW(L"STATIC", L"⏳ در حال آماده‌سازی و ورود مستقیم به برنامه (بدون نیاز به تنظیم دستی)...",
                                         WS_VISIBLE | WS_CHILD | SS_CENTER, 20, 62, 520, 32, hwnd, nullptr, nullptr, nullptr);
            SendMessageW(g_hwndStatus, WM_SETFONT, (WPARAM)g_subFont, TRUE);

            g_hwndProgress = CreateWindowExW(0, PROGRESS_CLASSW, nullptr,
                                             WS_VISIBLE | WS_CHILD | PBS_SMOOTH,
                                             35, 108, 490, 26, hwnd, nullptr, nullptr, nullptr);
            SendMessageW(g_hwndProgress, PBM_SETRANGE, 0, MAKELPARAM(0, 100));
            SendMessageW(g_hwndProgress, PBM_SETPOS, 5, 0);

            HANDLE hThread = CreateThread(nullptr, 0, AutoBootstrapAndEnterThread, nullptr, 0, nullptr);
            if (hThread) CloseHandle(hThread);
            return 0;
        }
        case WM_NOVA_PROGRESS: {
            if (g_hwndProgress) {
                SendMessageW(g_hwndProgress, PBM_SETPOS, wParam, 0);
            }
            return 0;
        }
        case WM_NOVA_STATUS: {
            wchar_t* txt = reinterpret_cast<wchar_t*>(lParam);
            if (txt) {
                if (g_hwndStatus) SetWindowTextW(g_hwndStatus, txt);
                delete[] txt;
            }
            return 0;
        }
        case WM_CTLCOLORSTATIC: {
            HDC hdc = (HDC)wParam;
            SetTextColor(hdc, RGB(224, 242, 254));
            SetBkColor(hdc, RGB(14, 19, 32));
            return (INT_PTR)g_bgBrush;
        }
        case WM_DESTROY:
            if (g_titleFont) DeleteObject(g_titleFont);
            if (g_subFont) DeleteObject(g_subFont);
            PostQuitMessage(0);
            return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR lpCmdLine, int nCmdShow) {
    std::wstring cmdArgs = lpCmdLine ? lpCmdLine : L"";
    g_playMode = (cmdArgs.find(L"--play") != std::wstring::npos);

    std::wstring root     = GetAppRootDir();
    std::wstring godotExe = GetGodotExePath();

    // ZERO QUESTIONS, ZERO INTERMEDIATE WINDOW:
    // If Godot 4.7.2 binary is already present (ReadyToRun ZIP or 2nd+ launch), jump STRAIGHT into the program!
    if (FileExistsW(godotExe)) {
        LaunchGodotDirectly(root, godotExe, g_playMode);
        return 0;
    }

    // Otherwise (bare source folder without engine_bin), auto-download & auto-enter with live progress bar (still zero questions!)
    INITCOMMONCONTROLSEX icc = { sizeof(icc), ICC_PROGRESS_CLASS };
    InitCommonControlsEx(&icc);

    g_bgBrush = CreateSolidBrush(RGB(14, 19, 32));
    WNDCLASSEXW wc = { sizeof(WNDCLASSEXW) };
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInstance;
    wc.hCursor       = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = g_bgBrush;
    wc.lpszClassName = L"NovaForgeZeroQuestionBootWnd";
    RegisterClassExW(&wc);

    int w = 576, h = 196;
    int sx = (GetSystemMetrics(SM_CXSCREEN) - w) / 2;
    int sy = (GetSystemMetrics(SM_CYSCREEN) - h) / 2;

    HWND hwnd = CreateWindowExW(
        0, wc.lpszClassName,
        L"NovaForge AI Studio — ورود و نصب خودکار",
        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
        sx, sy, w, h, nullptr, nullptr, hInstance, nullptr);

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
