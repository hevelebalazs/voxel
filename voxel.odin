package voxel

import win "core:sys/windows"
import d3d11 "vendor:directx/d3d11"
import dxgi "vendor:directx/dxgi"

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
	
	device : ^d3d11.IDevice
	device_context : ^d3d11.IDeviceContext
	{
		device0 : ^d3d11.IDevice
		device_context0 : ^d3d11.IDeviceContext
		feature_levels : []d3d11.FEATURE_LEVEL =
			{d3d11.FEATURE_LEVEL._11_0}
		creation_flags := d3d11.CREATE_DEVICE_FLAGS{.BGRA_SUPPORT}
		
		result := d3d11.CreateDevice(nil, d3d11.DRIVER_TYPE.HARDWARE,
			nil, creation_flags, &feature_levels[0], 
			u32(len(feature_levels)), d3d11.SDK_VERSION, &device0, nil,
			&device_context0)
			
		if win.FAILED(result) {
			assert(false)
			return
		}
		
		result = device0->QueryInterface(d3d11.IDevice_UUID,
			(^rawptr)(&device))
		assert(win.SUCCEEDED(result))
		device0->Release()
		
		result = device_context0->QueryInterface(
			d3d11.IDeviceContext_UUID, (^rawptr)(&device_context))
		assert(win.SUCCEEDED(result))
		device_context0->Release()
	}
	
	swap_chain : ^dxgi.ISwapChain1
	{
		dxgi_factory : ^dxgi.IFactory2
		{
			dxgi_device : ^dxgi.IDevice1
			result := device->QueryInterface(dxgi.IDevice1_UUID,
				(^rawptr)(&dxgi_device))
			assert(win.SUCCEEDED(result))
			
			dxgi_adapter : ^dxgi.IAdapter
			result = dxgi_device->GetAdapter(&dxgi_adapter)
			assert(win.SUCCEEDED(result))
			dxgi_device->Release()
			
			adapter_desc : dxgi.ADAPTER_DESC;
			dxgi_adapter->GetDesc(&adapter_desc)
			
			result = dxgi_adapter->GetParent(dxgi.IFactory2_UUID,
				(^rawptr)(&dxgi_factory))
			assert(win.SUCCEEDED(result))
			dxgi_adapter->Release()
		}
		
		swap_chain_desc := dxgi.SWAP_CHAIN_DESC1 {
			Width = 0,
			Height = 0,
			Format = dxgi.FORMAT.B8G8R8A8_UNORM_SRGB,
			SampleDesc = {
				Count = 1,
				Quality = 0
			},
			BufferUsage = {.RENDER_TARGET_OUTPUT},
			BufferCount = 2,
			Scaling = dxgi.SCALING.STRETCH,
			SwapEffect = dxgi.SWAP_EFFECT.DISCARD,
			AlphaMode = dxgi.ALPHA_MODE.UNSPECIFIED,
			Flags = {}
		}
		
		result := dxgi_factory->CreateSwapChainForHwnd(device,
			window, &swap_chain_desc, nil, nil, &swap_chain)
		assert(win.SUCCEEDED(result))
		
		dxgi_factory->Release()
	}
	
	frame_buffer_view : ^d3d11.IRenderTargetView
	{
		frame_buffer : ^d3d11.ITexture2D
		result := swap_chain->GetBuffer(0, d3d11.ITexture2D_UUID,
			(^rawptr)(&frame_buffer))
		assert(win.SUCCEEDED(result))
		
		result = device->CreateRenderTargetView(frame_buffer, nil,
			&frame_buffer_view)
		assert(win.SUCCEEDED(result))
		frame_buffer->Release()
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
		
		background_color := [4]f32{0.1, 0.2, 0.6, 1.0}
		device_context->ClearRenderTargetView(frame_buffer_view,
			&background_color)
			
		swap_chain->Present(1, nil)
	}
}
