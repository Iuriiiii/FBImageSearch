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
    	As Double pixel_tolerance,image_tolerance ' The image tolerance and pixel comparison tolerance.
End Type
```
