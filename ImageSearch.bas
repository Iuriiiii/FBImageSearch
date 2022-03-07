#Include Once "windows.bi"
#Include Once "crt.bi"
#Include Once "win/shlwapi.bi"
#include Once "file.bi"
#include Once "win/GdiPlus.bi"

Function getBitmapFromWindow(ByRef win As HWND = 0, _
									  ByVal x As Integer = 0, _
								 	  ByVal y As Integer = 0, _
								 	  ByRef w As Integer = 0, _
								 	  ByRef h As Integer = 0, _
								 	  ByRef wdc As HDC = 0, _
								 	  ByVal cdc As HDC = 0) As HBITMAP
	win = Iif(win,win,GetDesktopWindow())
	wdc = GetWindowDC(win)
	cdc = CreateCompatibleDC(wdc)
	
	If w = 0 And h = 0 then
		Dim rc As RECT
		GetWindowRect(win,@rc)
		w = rc.right - rc.left
		h = rc.bottom - rc.top
	EndIf
	
	Dim hbmp as HBITMAP = CreateCompatibleBitmap(wdc,w,h)
	Dim hold As HGDIOBJ = SelectObject(cdc,hbmp)
	Dim status As BOOL = BitBlt(cdc,x,y,w,h,wdc,0,0,SRCCOPY)
	SelectObject(cdc,hold)
	DeleteDC(cdc)

	If status = FALSE then
		DeleteObject(hbmp)
		Return NULL
	EndIf
	
	Return hbmp
End Function

Private Function GetArrayFromHWND(ByVal win As HWND = 0, _
											 ByVal x As Integer = 0, _
								 	  		 ByVal y As Integer = 0, _
								 	  		 ByRef w As Integer = 0, _
								 	  		 ByRef h As Integer = 0, _
										 	 ByRef stride As Integer = 0) As Any Ptr
	Dim wdc as HDC
	Dim cdc as HDC
	Dim hbmp as HBITMAP = getBitmapFromWindow(win,x,y,w,h,wdc,cdc)
	Dim bmpinfo As BITMAPINFO
	Dim buff As Any Ptr
	
	bmpinfo.bmiHeader.biSize = SizeOf(bmpinfo.bmiHeader)

	If GetDIBits(wdc,hbmp,0,0,NULL,@bmpinfo,DIB_RGB_COLORS) = FALSE Then
		GoTo FAILURE
	EndIf
	
	buff = CAllocate(1,bmpinfo.bmiHeader.biSizeImage)
	bmpinfo.bmiHeader.biCompression = BI_RGB
	bmpinfo.bmiHeader.biHeight = abs(bmpinfo.bmiHeader.biHeight)
	stride = (bmpinfo.bmiHeader.biWidth * (bmpinfo.bmiHeader.biBitCount / 8) + 3) And Not 3
	
	If GetDIBits(wdc,hbmp,0,bmpinfo.bmiHeader.biHeight,Cast(LPVOID,buff),@bmpinfo,DIB_RGB_COLORS) = FALSE Then
		GoTo FAILURE
	EndIf
	
	GoTo SUCCESS
FAILURE:
	If buff Then
		Deallocate(buff)
		buff = NULL
	EndIf
SUCCESS:
	DeleteObject(hbmp)
	ReleaseDC(win,wdc)
	DeleteDC(wdc)
	
	Return buff
End Function

Function _FileExists(szPath As String) As BOOL
  Dim dwAttrib As DWORD = GetFileAttributes(szPath)
  return (dwAttrib <> INVALID_FILE_ATTRIBUTES And Not(dwAttrib And FILE_ATTRIBUTE_DIRECTORY))
End Function

Function GetArrayFromImageFile(path As String, _
										 ByRef w As Integer = 0, _
										 ByRef h As Integer = 0, _
										 ByRef stride As Integer = 0) As Any Ptr
	
	
	If FileExists(path) = FALSE Then
		Print "File not exists."
		Return NULL
	EndIf
	
	'Select Case *PathFindExtensionA(StrPtr(path))
	'	Case ".bmp"
	'		hbmp = LoadImageA(NULL,path,IMAGE_BITMAP,0,0,LR_LOADFROMFILE)
	'	Case ".png"
	'End Select
	Dim gbmp As GdiPlus.GpBitmap Ptr
	Dim hbmp As HBITMAP
	
	If GdiPlus.GdipCreateBitmapFromFile(path,@gbmp) = FALSE Then
		GdiPlus.GdipCreateHBITMAPFromBitmap(gbmp,@hbmp,&HFFFFFF)
		DeleteObject(gbmp)
	EndIf
	
	'Print "hbmp:",Str(hbmp)
	
	Dim bmpinfo As BITMAPINFO
	Dim buff As Any Ptr
	Dim pdc As HDC = GetDC(0)
	
	bmpinfo.bmiHeader.biSize = SizeOf(bmpinfo.bmiHeader)

	If GetDIBits(pdc,hbmp,0,0,NULL,@bmpinfo,DIB_RGB_COLORS) = FALSE Then
		GoTo FAILURE
	EndIf
	
	w = bmpinfo.bmiHeader.biWidth
	h = bmpinfo.bmiHeader.biHeight
	buff = CAllocate(1,bmpinfo.bmiHeader.biSizeImage)
	bmpinfo.bmiHeader.biCompression = BI_RGB
	bmpinfo.bmiHeader.biHeight = abs(bmpinfo.bmiHeader.biHeight)
	stride = (bmpinfo.bmiHeader.biWidth * (bmpinfo.bmiHeader.biBitCount / 8) + 3) And Not 3
	
	If GetDIBits(pdc,hbmp,0,bmpinfo.bmiHeader.biHeight,Cast(LPVOID,buff),@bmpinfo,DIB_RGB_COLORS) = FALSE Then
		GoTo FAILURE
	EndIf
	
	GoTo SUCCESS
FAILURE:
	If buff Then
		Deallocate(buff)
		buff = NULL
	EndIf
SUCCESS:
	DeleteObject(hbmp)
	ReleaseDC(0,pdc)
	DeleteDC(pdc)
	
	Return buff
End Function

#define TRANSPARENCY_VALUE Cast(Long,&HFFFFFFFF)'Cast(Long,&HFF001EFF)

Type SEARCH_IMAGE_DATA
	file As String
	transparency As Long = TRANSPARENCY_VALUE
	toleration As Long
	algorithm As Long
	hwnd As HWND
End Type

Type SEARCH_IMAGE_RETURN
	As Integer error,found
	As Long x,y,middle_x,middle_y,width,height
End Type

Private Type LONG_STACK
		memory(Any) As Integer
		Declare Constructor()
		Declare Destructor()
		Declare Sub Push(ByVal v As Integer)
		'Declare Function Peek() As Long
End Type

Constructor LONG_STACK()
	ReDim This.memory(0)
End Constructor

Destructor LONG_STACK()
	Erase This.memory
End Destructor

'Function LONG_STACK.Peek() As Long
'	If Ubound(This.memory) = 0 Then Return 0
'	Return This.memory(Ubound(This.memory) - 1)
'End Function

Sub LONG_STACK.Push(ByVal v As Integer)
	Dim u As Integer = Ubound(This.memory)
	ReDim Preserve This.memory(u + 1)
	This.memory(u) = v
End Sub

Type SEARCH_IMAGE_DATA_POSITION
	status As Integer
	first_pixel As Long
	addresses As LONG_STACK Ptr
	lengths As LONG_STACK Ptr
	x As LONG_STACK Ptr
	y As LONG_STACK Ptr
	width As Long
	height As Long
	npixels As Long
End Type

Private Sub GetArrayOfLocations(ByVal barrayf As UByte Ptr, _
										  ByVal w As Integer, _
										  ByVal h As Integer, _
										  ByVal stride As Integer, _
										  ret As SEARCH_IMAGE_DATA_POSITION, _
										  ByVal transparency As Long = TRANSPARENCY_VALUE)
	Dim As Integer y,x,basex,basey,maxx,maxy
	Dim As Integer minx = 99999
	Dim As Integer miny = 99999
	
	ret.addresses = New LONG_STACK
	ret.lengths = New LONG_STACK
	ret.y = New LONG_STACK
	ret.x = New LONG_STACK

	For y = 0 To (h - 1)
		Dim rowBase As Long = y * stride
		For x = 0 To (w - 1)
			#define ppixel(p) Cast(Long Ptr,(barrayf+rowBase+p*4))
			#define pixel(p) *ppixel(p)
			
			If pixel(x) <> transparency Then
				If x < minx Then
					minx = x
				EndIf
				If ret.status = FALSE Then
					ret.first_pixel = pixel(x)
					miny = y
					basex = x
					basey = y
					ret.status = TRUE
				EndIf
				ret.y->Push(y - basey)
				ret.x->Push(x - basex)
				ret.addresses->Push(Cast(Integer,ppixel(x)))
				Dim k As Integer = x
				For x = x+1 To (w - 1)
					If pixel(x) = transparency Then
						Exit For
					EndIf
					'Print Str(pixel(x))
				Next
				#define length (x-1) - k
				ret.lengths->Push(length)
				If x > maxx Then
					maxx = x
				EndIf
				If y > maxy Then
					maxy = y
				EndIf
				ret.npixels += length
			EndIf
		Next
	Next
	ret.height = (maxy + 1) - miny
	ret.width = maxx - minx
End Sub

Public Enum SEARCH_IMAGE_ALGORITHM
	standard = 0
	tolerance
	double_tolerance
	randomized
	diminutive
End Enum

Type SEARCH_IMAGE_DATA_EX
	As Integer i1w,i1h,i1s
	As Integer i2w,i2h,i2s
	As Any Ptr image1_bytes,image2_bytes
	As Long x,y
	transparency As Long = TRANSPARENCY_VALUE
	algorithm As SEARCH_IMAGE_ALGORITHM
	As Double pixel_tolerance,image_tolerance
End Type

Function SearchImageEx(param As SEARCH_IMAGE_DATA_EX) As SEARCH_IMAGE_RETURN Ptr
	
	#define BAD_RETURN(code) Cast(SEARCH_IMAGE_RETURN Ptr,code)
	
	If param.image1_bytes = 0 Then
		Return BAD_RETURN(1)
	ElseIf param.image2_bytes = 0 Then
		Return BAD_RETURN(2)
	EndIf
	
	If (param.i1w * param.i1h) > (param.i2w * param.i2h) Then
		Return BAD_RETURN(3)
	EndIf
	
	If param.x < 0 Then
		Return BAD_RETURN(4)
	ElseIf param.y < 0 Then
		Return BAD_RETURN(5)
	EndIf
	
	Dim sidp As SEARCH_IMAGE_DATA_POSITION
	
	GetArrayOfLocations(param.image1_bytes,param.i1w,param.i1h,param.i1s,sidp,(param.transparency))
	
	If sidp.status = FALSE Then
		Delete sidp.addresses
		Delete sidp.lengths
		Delete sidp.x
		Delete sidp.y
		Return BAD_RETURN(6)
	EndIf
	
	#define row(_y,_stride) ((_y) * _stride)
	
	Dim As Long y,x,i,k
	Dim tolerance As Long = Int(param.pixel_tolerance * &HFF)
	Dim imgtolerance As Double = param.image_tolerance
	Dim fixedw As Long = ((param.i2w - 1) - (sidp.width - 1))
	Dim fixedh As Long = ((param.i2h - 1) - (sidp.height - 1))
	
	For y = param.y To fixedh
		Dim i2r As Integer = row(y,param.i2s)
		'Print Str(i2r)
		
		For x = param.x To fixedw
			#define pixelMem(_array,_stride,_x) Cast(Long Ptr,(_array+(_stride))+(_x)*SizeOf(Long))
			#define pixel(_array,_stride,_x) *pixelMem(_array,_stride,_x)
			#define pixelEx(_array,_stride,_x,_extra) *pixelMem(_array,_stride,(_x+_extra))
			
			If pixel(param.image2_bytes,i2r,x) = sidp.first_pixel Then
				Dim cloop As Integer = TRUE
				Dim pixelfailcounter As Long = 0
				
				For i = 0 To Ubound(sidp.addresses->memory) - 1
					#define address Cast(Long Ptr,sidp.addresses->memory(i))
					#define address_length sidp.lengths->memory(i)
					#define ix sidp.x->memory(i)
					#define iy sidp.y->memory(i)
					#define cpixels sidp.npixels
					
					If param.algorithm = SEARCH_IMAGE_ALGORITHM.standard Then
						For k = 0 To address_length - 1
							If *(address+k) <> pixel(param.image2_bytes,row(y+iy,param.i2s),x+ix+k) Then
								cloop = FALSE
								Exit For, For
							EndIf
						Next
						
					ElseIf param.algorithm = SEARCH_IMAGE_ALGORITHM.double_tolerance Then
						For k = 0 To address_length - 1
							Dim p As Long = pixel(param.image2_bytes,row(y+iy,param.i2s),x+k)
							Dim minTolerance As Long = p - tolerance
							Dim maxTolerance As Long = p + tolerance
						
							If maxTolerance < *(address+k) Or minTolerance > *(address+k) Then
								pixelfailcounter += 1
								
								If (cpixels * (pixelfailcounter / 100)) > imgtolerance Then
									cloop = FALSE
									Exit For, For
								EndIf
							EndIf
						Next
						
					ElseIf param.algorithm = SEARCH_IMAGE_ALGORITHM.tolerance Then
						For k = 0 To address_length - 1
							Dim p As Long = pixel(param.image2_bytes,row(y+iy,param.i2s),x+k)
							Dim minTolerance As Long = p - tolerance
							Dim maxTolerance As Long = p + tolerance
						
							If maxTolerance < *(address+k) Or minTolerance > *(address+k) Then
								cloop = FALSE
								Exit For, For
							EndIf
						Next
						
					EndIf
				Next
				
				If cloop Then
					Dim ret As SEARCH_IMAGE_RETURN Ptr = New SEARCH_IMAGE_RETURN
					
					Delete sidp.addresses
					Delete sidp.lengths
					Delete sidp.x
					Delete sidp.y
					
					ret->found = TRUE
					ret->x = x
					ret->y = (param.i2h - y) - sidp.height ' Fixup
					ret->width = param.i1w
					ret->height = param.i1h
					ret->middle_x = ret->x + param.i1w / 2
					ret->middle_y = ret->y + param.i1h / 2
					
					Return ret
				EndIf
				
			EndIf
		Next
	Next
	
	Return BAD_RETURN(0)
End Function

Sub ImageSearch_Start()
	Dim gpStartupInput As GdiPlus.GdiplusStartupInput
	Static gpToken as ULONG_PTR
	gpStartupInput.GdiplusVersion = 1
	GdiPlus.GdiplusStartup(@gpToken,@gpStartupInput,NULL)
End Sub

Sub ImageSearch_End()
	Static gpToken as ULONG_PTR
	GdiPlus.GdiplusShutdown(gpToken)
End Sub


