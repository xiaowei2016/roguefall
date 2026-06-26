using Godot;
using System;
using System.Runtime.InteropServices;

public partial class DesktopPixelPassthrough : Node
{
    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr GetWindowLongPtr(IntPtr hWnd, int nIndex);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SetWindowLongPtr(IntPtr hWnd, int nIndex, IntPtr dwNewLong);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr GetForegroundWindow();

    private const int GWL_EXSTYLE = -20;
    private static readonly IntPtr WS_EX_LAYERED = (IntPtr)0x00080000;
    private static readonly IntPtr WS_EX_TRANSPARENT = (IntPtr)0x00000020;

    private IntPtr _hWnd;
    private bool _isPassthrough = true;
    private int _lastState = -1; // 0=passthrough, 1=opaque, -1=force refresh
    private Vector2I _lastMousePos = new(-1, -1);

    private const float AlphaThreshold = 0.1f;

    // Log throttle: always log on state change; idle log every N frames
    private uint _frameCount = 0;
    private const uint LogThrottleFrames = 60;
    private float _lastAlpha = -1f;

    // Debug switch: false disables per-frame alpha/pos logs and no-change SWITCH logs
    private const bool DEBUG_PIXEL_PASSTHROUGH = false;

    public override void _Ready()
    {
        _hWnd = (IntPtr)DisplayServer.WindowGetNativeHandle(
            DisplayServer.HandleType.WindowHandle, 0);

        var style = GetWindowLongPtr(_hWnd, GWL_EXSTYLE);
        var desired = ToUIntPtr(style) | ToUIntPtr(WS_EX_LAYERED);
        SetWindowLongPtr(_hWnd, GWL_EXSTYLE, (IntPtr)desired);

        GD.Print($"[PixelPassthrough] Ready  hwnd=0x{_hWnd:X}  exstyle=0x{desired:X}");
    }

    public override void _Process(double delta)
    {
        if (_hWnd == IntPtr.Zero)
            return;

        _frameCount++;

        var win = GetWindow();
        if (win == null)
            return;

        // Use DisplayServer for screen-space mouse position, then convert to window-local
        var screenMouse = DisplayServer.MouseGetPosition();
        var winPos = win.Position;
        var mouseLocal = screenMouse - winPos;

        var viewport = GetViewport();
        if (viewport == null)
            return;

        var viewportSize = viewport.GetVisibleRect().Size;

        // Mouse outside window bounds → passthrough
        if (mouseLocal.X < 0 || mouseLocal.Y < 0 ||
            mouseLocal.X >= viewportSize.X || mouseLocal.Y >= viewportSize.Y)
        {
            ApplyPassthroughState(true, -1f, mouseLocal);
            return;
        }

        // Read the pixel alpha from the current viewport render
        var tex = viewport.GetTexture();
        if (tex == null)
            return;

        var img = tex.GetImage();
        if (img == null)
            return;

        var pixel = img.GetPixel(mouseLocal.X, mouseLocal.Y);

        bool shouldPassthrough = pixel.A <= AlphaThreshold;

        // Only call Windows API on actual state change
        var newState = shouldPassthrough ? 0 : 1;
        bool stateChanged = (newState != _lastState);
        bool mouseMoved = (mouseLocal != _lastMousePos);

        if (stateChanged)
        {
            ApplyPassthroughState(shouldPassthrough, pixel.A, mouseLocal);
        }
        else if (DEBUG_PIXEL_PASSTHROUGH && mouseMoved && _frameCount % LogThrottleFrames == 0)
        {
            // Idle periodic log (only when DEBUG_PIXEL_PASSTHROUGH=true)
            GD.Print($"[PixelPassthrough] alpha={pixel.A:F3} pos=({mouseLocal.X},{mouseLocal.Y}) passthrough={shouldPassthrough}");
        }

        _lastMousePos = mouseLocal;
        _lastAlpha = pixel.A;
    }

    private void ApplyPassthroughState(bool enable, float alpha, Vector2I pos)
    {
        var style = GetWindowLongPtr(_hWnd, GWL_EXSTYLE);
        IntPtr newStyle;

        if (enable)
        {
            newStyle = (IntPtr)(ToUIntPtr(style) | ToUIntPtr(WS_EX_TRANSPARENT));
        }
        else
        {
            newStyle = (IntPtr)(ToUIntPtr(style) & ~ToUIntPtr(WS_EX_TRANSPARENT));
        }

        // Always keep WS_EX_LAYERED
        newStyle = (IntPtr)(ToUIntPtr(newStyle) | ToUIntPtr(WS_EX_LAYERED));

        bool exstyleChanged = (ToUIntPtr(style) != ToUIntPtr(newStyle));

        if (exstyleChanged)
        {
            SetWindowLongPtr(_hWnd, GWL_EXSTYLE, newStyle);
        }

        _isPassthrough = enable;
        _lastState = enable ? 0 : 1;

        // Only log SWITCH on real exstyle change
        if (exstyleChanged)
        {
            var oldHex = ToUIntPtr(style);
            var newHex = ToUIntPtr(newStyle);
            GD.Print($"[PixelPassthrough] SWITCH  passthrough={enable}  alpha={alpha:F3}  pos=({pos.X},{pos.Y})  exstyle: 0x{oldHex:X} → 0x{newHex:X}");
        }
    }

    private static UIntPtr ToUIntPtr(IntPtr p) => (UIntPtr)(ulong)p.ToInt64();
}
