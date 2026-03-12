package voxel

import win "core:sys/windows"

win_proc :: proc "stdcall" (window: win.HWND, message: win.UINT,
		wparam: win.WPARAM, lparam: win.LPARAM) -> win.LRESULT {
	switch(message) {
		case win.WM_KEYDOWN: {
			if wparam == win.VK_ESCAPE {
				win.DestroyWindow(window)
			}
		}
		case win.WM_DESTROY: {
			win.PostQuitMessage(0)
		}
	}

	return win.DefWindowProcW(window, message, wparam, lparam)
}

main :: proc() {
	instance := win.HINSTANCE(win.GetModuleHandleA(nil))

	win_class := win.WNDCLASSEXW {
		cbSize = size_of(win.WNDCLASSEXW),
		style = win.CS_HREDRAW | win.CS_VREDRAW,
		lpfnWndProc = win_proc,
		hInstance = instance,
		hIcon = win.LoadIconA(nil, win.IDC_ARROW),
		hCursor = win.LoadCursorA(nil, win.IDC_ARROW),
		lpszClassName = win.L("VoxelWindowClass"),
		hIconSm = win.LoadIconA(nil, win.IDI_APPLICATION)
	}

	if win.RegisterClassExW(&win_class) == 0 {
		assert(false)
		return
	}
	
	rect := win.RECT{0, 0, 1024, 768}
	win.AdjustWindowRectEx(&rect, win.WS_OVERLAPPEDWINDOW, win.FALSE,
		win.WS_EX_OVERLAPPEDWINDOW)
	
	width := win.LONG(rect.right - rect.left)
	height := win.LONG(rect.bottom - rect.top)
	
	window := win.CreateWindowExW(win.WS_EX_OVERLAPPEDWINDOW,
		win_class.lpszClassName,
		win.L("Voxel"),
		win.WS_OVERLAPPEDWINDOW | win.WS_VISIBLE,
		win.CW_USEDEFAULT, win.CW_USEDEFAULT,
		width, height, nil, nil, instance, nil)
		
	if window == nil {
		assert(false)
		return
	}
	
	running := true
	for running {
		message : win.MSG;
		for win.PeekMessageW(&message, nil, 0, 0, win.PM_REMOVE) {
			if message.message == win.WM_QUIT {
				running = false
			}
			
			win.TranslateMessage(&message)
			win.DispatchMessageW(&message);
		}
		
		win.Sleep(1)
	}
}
