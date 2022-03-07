### [FreeBasic] ImageSearch

------------

##### Features
- Stupidly fast
- Lightweight
- Supports to BMP, GIF, JPEG, PNG, TIFF, Exif, WMF, and EMF image formats
- Multiple search algorithms available
- Excelent transparency implementation
- Ability to search on windows or images

##### Usage
At first, you should call `ImageSearch_Start()` to initialize the search motor. After this, we need to initialize a structure `SEARCH_IMAGE_DATA_EX` with the data that we will search.

###### The SEARCH_IMAGE_DATA_EX structure
This structure will contains the data that we will search and compare, also the search algorithm and its transparency value.

```vb
Type SEARCH_IMAGE_DATA_EX
    	As Integer i1w,i1h,i1s ' INTERNAL USAGE
    	As Integer i2w,i2h,i2s ' INTERNAL USAGE
    	As Any Ptr image1_bytes ' Array of byte of the image to search
        As Any Ptr image2_bytes ' Array of byte of the image container
    	As Long x,y ' X and Y location from start
    	transparency As Long = TRANSPARENCY_VALUE ' The transparency value, default green
    	algorithm As SEARCH_IMAGE_ALGORITHM ' The search algorithm, default SEARCH_IMAGE_ALGORITHM.standard
    	As Double pixel_tolerance,image_tolerance ' The image tolerance and pixel comparison tolerance
End Type
```

We can get the array of byte of an image  with `GetArrayFromImageFile(image_path)` function, or from a window with `GetArrayFromHWND([window_handle=desktop])`.  With this last function will be your job find out the correct window handle of the window that you want scan, by default the scan window is the whole desktop, being all its parameters optionals.

###### The SEARCH_IMAGE_RETURN structure
This structure contains the data of the found image.

```vb
Type SEARCH_IMAGE_RETURN
	As Integer error
	As Integer found ' TRUE if found... FALSE otherwise
	As Long x ' X location
	As Long y ' Y location
	As Long middle_x ' The middle X location of the image
	As Long middle_y ' The middle Y location of the image
	As Long width ' The image width
	As Long height ' The image height
End Type
```

Knowing this, we can do the following:

```vb
Function check(returnData As SEARCH_IMAGE_RETURN Ptr) As Integer
	Return Not (returnData >= 0 and returnData <= 10) 
End Function

ImageSearch_Start()

Dim searchData As SEARCH_IMAGE_DATA_EX

searchData.image1_bytes = GetArrayFromImageFile("image.bmp")
searchData.image2_bytes = GetArrayFromHWND() ' Or GetArrayFromImageFile("another_image.bmp")

Dim returnData As SEARCH_IMAGE_RETURN Ptr = SearchImageEx(searchData)

If check(returnData) Then
	If returnData.found Then
		' Do Something
	End If
End If
```

You might  use the `Delete` instruction to free the memory of `ìmage1_bytes`, `image2_bytes` members and the return of the `SearchImageEx`.
